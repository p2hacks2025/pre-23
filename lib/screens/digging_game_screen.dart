import 'dart:math';
import 'dart:io';
import 'dart:ui'; // ★ 重要: ImageFilterのために追加
import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../models/game.dart';

class DiggingGameScreen extends StatefulWidget {
  final List<Memory> undiscoveredMemories;
  final Function(Memory) onDiscover;
  final Function(Item) onDiscoverItem;
  final int dailyDigs;
  final Function(int) onDailyDigsChanged;

  const DiggingGameScreen({
    super.key,
    required this.undiscoveredMemories,
    required this.onDiscover,
    required this.onDiscoverItem,
    required this.dailyDigs,
    required this.onDailyDigsChanged,
  });

  @override
  State<DiggingGameScreen> createState() => _DiggingGameScreenState();
}

class _DiggingGameScreenState extends State<DiggingGameScreen> with TickerProviderStateMixin {
  Memory? _targetMemory;
  int _clickCount = 0;
  int _requiredClicks = 10;
  bool _isFinished = false;

  late AnimationController _breakController;

  @override
  void initState() {
    super.initState();
    _breakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _setupGame();
  }

  void _setupGame() {
    if (widget.undiscoveredMemories.isEmpty) {
      setState(() => _targetMemory = null);
      return;
    }
    setState(() {
      _targetMemory = widget.undiscoveredMemories[Random().nextInt(widget.undiscoveredMemories.length)];
      final daysPassed = DateTime.now().difference(_targetMemory!.createdAt).inDays;
      if (daysPassed > 180) _requiredClicks = 5;
      else if (daysPassed > 7) _requiredClicks = 20;
      else _requiredClicks = 10;
      
      _clickCount = 0;
      _isFinished = false;
      _breakController.reset();
    });
  }

  void _handleTap() {
    if (_isFinished || _targetMemory == null) return;
    setState(() {
      _clickCount++;
      if (_clickCount >= _requiredClicks) {
        _isFinished = true;
        _breakController.forward().then((_) => widget.onDiscover(_targetMemory!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_targetMemory == null) {
      return const Center(child: Text("未発掘の記憶はありません", style: TextStyle(color: Colors.white)));
    }

    double opacity = (1.0 - (_clickCount / _requiredClicks)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildInfoSection(),
          Expanded(
            child: GestureDetector(
              onTap: _handleTap,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildMemoryImage(),
                    if (!_isFinished) _buildIceFilter(opacity),
                    if (_isFinished) _buildBreakEffect(),
                  ],
                ),
              ),
            ),
          ),
          _buildFooterSection(),
        ],
      ),
    );
  }

  Widget _buildIceFilter(double opacity) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 320,
          height: 320,
          child: Stack(
            children: [
              // 1. 背後をぼかす（すりガラス効果）
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(color: Colors.white.withOpacity(0.1)),
              ),
              // 2. 氷の質感グラデーション
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.7),
                      Colors.cyan.withOpacity(0.2),
                      Colors.blue.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              // 3. 氷の結晶
              const Center(
                child: Icon(Icons.ac_unit, size: 80, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 以下の _buildMemoryImage, _buildBreakEffect 等は以前と同じ ---
  Widget _buildMemoryImage() {
    return Container(
      width: 320, height: 320,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _targetMemory!.photo.startsWith('http')
            ? Image.network(_targetMemory!.photo, fit: BoxFit.cover)
            : Image.file(File(_targetMemory!.photo), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBreakEffect() {
    return AnimatedBuilder(
      animation: _breakController,
      builder: (context, child) => Opacity(
        opacity: (1.0 - _breakController.value),
        child: Transform.scale(
          scale: 1.0 + (_breakController.value * 0.5),
          child: const Icon(Icons.flash_on, size: 200, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text("氷の厚さ: ${_requiredClicks - _clickCount} 層", 
        style: const TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooterSection() {
    return Container(padding: const EdgeInsets.all(40), child: const Text("タップして解凍", style: TextStyle(color: Colors.white70)));
  }

  @override
  void dispose() {
    _breakController.dispose();
    super.dispose();
  }
}