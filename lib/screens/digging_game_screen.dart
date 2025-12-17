// lib/screens/digging_game_screen.dart

import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../models/game.dart';

class DiggingGameScreen extends StatefulWidget {
  final List<Memory> undiscoveredMemories;
  final Function(Memory) onDiscover;
  final Function(Item) onDiscoverItem;
  final int dailyDigs;
  final Function(int) onDailyDigsChanged;

  // ★ 追加パラメータ: ゲスト情報とログイン誘導コールバック
  final bool isGuest;
  final VoidCallback onRequestLogin;

  const DiggingGameScreen({
    super.key,
    required this.undiscoveredMemories,
    required this.onDiscover,
    required this.onDiscoverItem,
    required this.dailyDigs,
    required this.onDailyDigsChanged,
    // 初期値設定 (既存コードへの影響を最小限にするため)
    this.isGuest = false,
    required this.onRequestLogin,
  });

  @override
  State<DiggingGameScreen> createState() => _DiggingGameScreenState();
}

class _DiggingGameScreenState extends State<DiggingGameScreen> with TickerProviderStateMixin {
  // ... (既存の変数定義はそのまま)
  Memory? _targetMemory;
  int _clickCount = 0;
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
    if (!mounted) return;
    if (widget.undiscoveredMemories.isEmpty) {
      setState(() => _targetMemory = null);
      return;
    }
    setState(() {
      _targetMemory = widget.undiscoveredMemories[Random().nextInt(widget.undiscoveredMemories.length)];
      _clickCount = 0;
      _isFinished = false;
      _breakController.reset();
    });
  }

  void _handleTap() {
    if (_isFinished || _targetMemory == null) return;

    setState(() {
      _clickCount++;
      if (_clickCount >= _targetMemory!.requiredClicks) {
        _isFinished = true;
        _breakController.forward().then((_) {
          if (mounted) {
            // 発掘完了を親に通知 (DB更新など)
            widget.onDiscover(_targetMemory!);
            // リアクションダイアログを表示
            _showReactionDialog(context, _targetMemory!);
          }
        });
      }
    });
  }

  void _sendNotificationToAuthor({
    required String emoji,
    required String? authorId,
    required String memoryId,
  }) {
    if (authorId == null) return;
    debugPrint('【通知発信】Stack: $emoji -> $authorId');
    // TODO: Notification logic
  }

  void _showReactionDialog(BuildContext context, Memory memory) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.cyan.shade900.withOpacity(0.95), // withValues -> withOpacity互換
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('発掘成功！想いを届ける', 
          textAlign: TextAlign.center, 
          style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 画像表示部分 (省略なしで記述する場合は元のコードと同様)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: memory.photo.startsWith('http')
                    ? Image.network(memory.photo, fit: BoxFit.cover)
                    : Image.file(File(memory.photo), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Text('by ${memory.author}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            const SizedBox(height: 8),
            Text(memory.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 20),
            
            // ★ スタンプボタンエリア
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stampButton(ctx, '❄️', '雪の結晶', memory),
                _stampButton(ctx, '⛏️', '労い', memory),
                _stampButton(ctx, '🔥', '暖かさ', memory),
                _stampButton(ctx, '💡', 'ひらめき', memory),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stampButton(BuildContext ctx, String emoji, String label, Memory memory) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            // ★ ここでログインガード！
            if (widget.isGuest) {
              // ログインが必要であることを伝える（またはそのままログイン画面へ）
              // ダイアログは閉じずに、その上にログイン画面を重ねる、あるいは一旦閉じる
              // ここでは「一旦閉じてログイン画面へ」というフローにします
              
              Navigator.pop(ctx); // スタンプダイアログを閉じる
              widget.onRequestLogin(); // 親(Home)のログイン画面呼び出しを実行
              return;
            }

            // 通常処理
            _sendNotificationToAuthor(
              emoji: emoji, 
              authorId: memory.authorId, 
              memoryId: memory.id
            );
            
            Navigator.pop(ctx);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('投稿主に $emoji を届けました'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.cyan.shade700,
              ),
            );

            _setupGame(); 
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24)
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  // --- UI構築 (以下、既存コードとほぼ同じ) ---
  @override
  Widget build(BuildContext context) {
    if (_targetMemory == null) {
      return const Center(child: Text("未発掘の記憶はありません", style: TextStyle(color: Colors.white)));
    }

    double opacity = (1.0 - (_clickCount / _targetMemory!.requiredClicks)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 60),
          Text("氷の厚さ: ${_targetMemory!.requiredClicks - _clickCount} 層", 
            style: const TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold)),
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
          const Text("タップして解凍", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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

  Widget _buildIceFilter(double opacity) {
    // 既存コードと同じ (withValues 修正済みならそのままで)
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 320, height: 320,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.7),
                      Colors.cyan.withOpacity(0.2),
                      Colors.blue.withOpacity(0.1)
                    ],
                  ),
                ),
              ),
              const Center(child: Icon(Icons.ac_unit, size: 80, color: Colors.white54)),
            ],
          ),
        ),
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
  
  @override
  void dispose() {
    _breakController.dispose();
    super.dispose();
  }
}