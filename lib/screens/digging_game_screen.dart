import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import '../models/memory.dart';
import '../widgets/effects.dart';
//lib/screens/digging_game_screen.dart
class DiggingGameScreen extends StatefulWidget {
  final List<Memory> allOtherMemories;
  final Function(Memory) onDiscover;

  const DiggingGameScreen({super.key, required this.allOtherMemories, required this.onDiscover});

  @override
  State<DiggingGameScreen> createState() => _DiggingGameScreenState();
}

class _DiggingGameScreenState extends State<DiggingGameScreen> with TickerProviderStateMixin {
  Memory? _targetMemory;
  int _clickCount = 0;
  int _targetIceIndex = 0; 
  
  late AnimationController _shakeController;
  late AnimationController _shatterController;
  List<IceShard> _shards = [];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _shatterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _shatterController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_shatterController.isAnimating) return;
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0.0);
    setState(() => _clickCount++);
    if (_clickCount >= _targetMemory!.requiredClicks) _startShatterEffect();
  }

  void _startShatterEffect() {
    final random = Random();
    _shards = List.generate(15, (index) => IceShard(
      angle: random.nextDouble() * pi * 2,
      distance: 100.0 + random.nextDouble() * 150.0,
      size: 10.0 + random.nextDouble() * 30.0,
    ));
    HapticFeedback.heavyImpact();
    _shatterController.forward(from: 0.0).then((_) => _onFinishDigging());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _targetMemory != null ? _buildIceBreakingGame() : _buildMemoryList(),
    );
  }

  Widget _buildMemoryList() {
    final undiscoveredList = widget.allOtherMemories.where((m) => !m.discovered).toList();
    if (undiscoveredList.isEmpty) {
      return const Center(child: Text("発掘できる氷がなくなりました", style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: undiscoveredList.length,
      itemBuilder: (context, index) => _buildMemoryCard(undiscoveredList[index], index),
    );
  }

  Widget _buildIceBreakingGame() {
    double progress = (_clickCount / _targetMemory!.requiredClicks).clamp(0.0, 1.0);
    double iceOpacity = (1.0 - progress).clamp(0.0, 1.0);
    double blurSigma = iceOpacity * 20.0;

    return Container(
      width: double.infinity, height: double.infinity,
      color: Colors.black.withOpacity(0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("思い出を掘り起こそう", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 4)),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: Listenable.merge([_shakeController, _shatterController]),
            builder: (context, child) => Transform.translate(
              offset: Offset(sin(_shakeController.value * pi * 4) * 8, 0),
              child: child,
            ),
            child: GestureDetector(
              onTap: _handleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(image: _getImage(_targetMemory!.photo), fit: BoxFit.cover),
                    ),
                  ),
                  if (!_shatterController.isAnimating)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Opacity(
                        opacity: iceOpacity,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                          child: Container(
                            width: 300, height: 300,
                            decoration: BoxDecoration(
                              image: IceEffects.getIceDecoration(_targetIceIndex, opacity: 0.6),
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: CustomPaint(
                              painter: IceCrackPainter(progress: progress),
                              child: const Icon(Icons.ac_unit, size: 80, color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_shatterController.isAnimating)
                    ..._shards.map((shard) => AnimatedBuilder(
                      animation: _shatterController,
                      builder: (context, child) {
                        double t = _shatterController.value;
                        return Transform.translate(
                          offset: Offset(cos(shard.angle) * shard.distance * t, sin(shard.angle) * shard.distance * t + (200 * t * t)),
                          child: Transform.rotate(angle: t * pi * 2, child: Opacity(opacity: 1.0 - t, child: child)),
                        );
                      },
                      child: Container(width: shard.size, height: shard.size, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(2))),
                    )).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(_shatterController.isAnimating ? "成功！" : '残り: ${_targetMemory!.requiredClicks - _clickCount}回', style: const TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextButton(onPressed: () => setState(() => _targetMemory = null), child: const Text("キャンセル", style: TextStyle(color: Colors.white24))),
        ],
      ),
    );
  }

  void _onFinishDigging() {
    final memory = _targetMemory!;
    final TextEditingController _commentController = TextEditingController();
    widget.onDiscover(memory);
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B3E).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("発掘に成功しました！", style: TextStyle(color: Colors.cyan, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IceEffects.memoryDetailContent(memory),
              const SizedBox(height: 24),
              const Text("この思い出に彩りを添えましょう", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLength: 10,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "一言メッセージ",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  counterStyle: const TextStyle(color: Colors.cyan),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                memory.stampsCount++;
                if (_commentController.text.isNotEmpty) memory.guestComments.add(_commentController.text);
                _targetMemory = null; 
                _shatterController.reset();
              });
              Navigator.pop(context); 
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("キラキラを送って完了"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 45)),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: IceEffects.glassStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(aspectRatio: 16 / 9, child: Image(image: _getImage(memory.photo), fit: BoxFit.cover)),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Container(color: Colors.transparent)),
                      Opacity(
                        opacity: 0.6,
                        child: Container(decoration: BoxDecoration(image: IceEffects.getIceDecoration(index, opacity: 1.0))),
                      ),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, elevation: 8),
                          onPressed: () => setState(() { _targetMemory = memory; _clickCount = 0; _targetIceIndex = index; }),
                          icon: const Icon(Icons.hardware),
                          label: const Text("発掘する"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(memory.author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("${memory.digCount} Digs", style: const TextStyle(color: Colors.cyan, fontSize: 11)),
                ]),
                const SizedBox(height: 8),
                Text(memory.text, style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                IceEffects.buildStampCounter("✨", memory.stampsCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImage(String path) {
    if (path.startsWith('http') || kIsWeb) return NetworkImage(path);
    return FileImage(File(path));
  }
}

class IceShard {
  final double angle, distance, size;
  IceShard({required this.angle, required this.distance, required this.size});
}

class IceCrackPainter extends CustomPainter {
  final double progress;
  IceCrackPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.2) return;
    final paint = Paint()..color = Colors.white.withOpacity(0.8)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final path = Path();
    int crackLines = (progress * 12).toInt();
    for (int i = 0; i < crackLines; i++) {
      double startX = size.width / 2, startY = size.height / 2;
      path.moveTo(startX, startY);
      path.lineTo(startX + cos(i * 1.5) * (size.width / 2 * progress * 1.2), startY + sin(i * 2.0) * (size.height / 2 * progress * 1.2));
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(IceCrackPainter oldDelegate) => oldDelegate.progress != progress;
}