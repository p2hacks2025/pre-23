import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; // ★オーディオ追加
import '../models/memory.dart';
import '../widgets/effects.dart';

class DiggingGameScreen extends StatefulWidget {
  final List<Memory> allOtherMemories;
final Function(Memory, String?, bool) onDiscover;  const DiggingGameScreen({super.key, required this.allOtherMemories, required this.onDiscover});

  @override
  State<DiggingGameScreen> createState() => _DiggingGameScreenState();
}

class _DiggingGameScreenState extends State<DiggingGameScreen> with TickerProviderStateMixin {
  Memory? _targetMemory;
  int _clickCount = 0;
  int _targetIceIndex = 0; 
  int _calculatedRequiredClicks = 10; // ★ 動的に計算したクリック数を保持
  int _calculateDifficulty(DateTime createdAt) {
    final now = DateTime.now();
    final age = now.difference(createdAt);

    if (age.inHours < 1) {
      return 8;   // 生まれたて：サクサク
    } else if (age.inDays < 1) {
      return 15;  // 1日以内：標準
    } else if (age.inDays < 7) {
      return 30;  // 1週間以内：少し硬い
    } else {
      return 50;  // それ以上：永久凍土（カチカチ）
    }
  }
  // ★ 硬さに応じたラベルを取得
  String _getDifficultyLabel() {
    if (_calculatedRequiredClicks >= 50) return "【 永久凍土 】";
    if (_calculatedRequiredClicks >= 30) return "【 古い氷 】";
    if (_calculatedRequiredClicks <= 8) return "【 新しい氷 】";
    return "";
  }

  // ★ オーディオプレイヤーの定義
  final AudioPlayer _sePlayer = AudioPlayer(); // 効果音用
  final AudioPlayer _bgmPlayer = AudioPlayer(); // BGM用

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
    // ★ リソースの解放
    _sePlayer.dispose();
    _bgmPlayer.dispose();
    _shakeController.dispose();
    _shatterController.dispose();
    super.dispose();
  }

  

  void _stopBGM() {
    _bgmPlayer.stop();
  }

  void _handleTap() {
    if (_shatterController.isAnimating) return;
    HapticFeedback.mediumImpact();
    
    // タップ音（削る音）を入れる場合はここ
    // _sePlayer.play(AssetSource('sounds/ice_tap.mp3'), mode: PlayerMode.lowLatency);

    _shakeController.forward(from: 0.0);
    setState(() => _clickCount++);
if (_clickCount >= _calculatedRequiredClicks) _startShatterEffect();  }

  void _startShatterEffect() {
    // ★ 1. 氷が割れる音を再生
    _sePlayer.play(AssetSource('icebreak.mp3'));
    _stopBGM(); // 割れたらBGMを止める

    final random = Random();
    bool isRare = random.nextDouble() < 0.2;

    _shards = List.generate(25, (index) {
      Color shardColor = Colors.white.withOpacity(0.9);
      if (isRare) {
        shardColor = HSVColor.fromAHSV(1.0, random.nextDouble() * 360, 0.6, 1.0).toColor();
      }

      return IceShard(
        angle: random.nextDouble() * pi * 2,
        distance: 100.0 + random.nextDouble() * 200.0,
        size: 8.0 + random.nextDouble() * 25.0,
        color: shardColor,
      );
    });

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
    bool isShattering = _shatterController.isAnimating || _clickCount >= _calculatedRequiredClicks;
    int remaining = isShattering ? 0 : (_calculatedRequiredClicks - _clickCount).clamp(0, 1000);
    double progress = (_clickCount / _calculatedRequiredClicks).clamp(0.0, 1.0);
    
    double photoOpacity = 0.3 + (progress * 0.7); 
    double iceOpacity = (1.0 - progress).clamp(0.0, 1.0);
    double blurSigma = iceOpacity * 25.0;

    return Container(
      width: double.infinity, 
      height: double.infinity,
      color: Colors.black.withOpacity(0.95),
      // ★ 解決策：画面からはみ出してもスクロールできるようにする
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // ★ 解決策：Columnを必要最小限の高さにする
            children: [
              const Text(
                "思い出を掘り起こそう", 
                style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 4)
              ),
              const SizedBox(height: 10),
              Text(_getDifficultyLabel(), style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 20), // 40から20へ微調整
              
              // --- 氷のビジュアル部分 ---
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
                      // 思い出の画像
                      Opacity(
                        opacity: photoOpacity,
                        child: Container(
                          width: 280, height: 280, // ★ 300から280へ少しだけサイズダウン
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(image: _getImage(_targetMemory!.photo), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      // 氷のエフェクト
                      if (!_shatterController.isAnimating)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Opacity(
                            opacity: iceOpacity,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                              child: Container(
                                width: 280, height: 280, // ★ 画像サイズに合わせる
                                decoration: BoxDecoration(
                                  image: IceEffects.getIceDecoration(_targetIceIndex, opacity: 0.6),
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                ),
                                child: CustomPaint(
                                  painter: IceCrackPainter(progress: progress),
                                  child: const Icon(Icons.ac_unit, size: 60, color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // 破片エフェクト
                      if (_shatterController.isAnimating)
                        ..._shards.map((shard) => AnimatedBuilder(
                          animation: _shatterController,
                          builder: (context, child) {
                            double t = _shatterController.value;
                            return Transform.translate(
                              offset: Offset(cos(shard.angle) * shard.distance * t, sin(shard.angle) * shard.distance * t + (300 * t * t)),
                              child: Transform.rotate(angle: t * pi * 3, child: Opacity(opacity: 1.0 - t, child: child)),
                            );
                          },
                          child: Container(
                            width: shard.size, height: shard.size,
                            decoration: BoxDecoration(
                              color: shard.color, borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20), // 40から20へ微調整
              Text(
                _shatterController.isAnimating ? "成功！" : '残り: $remaining回', 
                style: const TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 10),
              
              TextButton(
                onPressed: () {
                  _stopBGM();
                  setState(() => _targetMemory = null);
                }, 
                child: const Text("キャンセル", style: TextStyle(color: Colors.white24))
              ),
            ],
          ),
        ),
      ),
    );
  }
 void _onFinishDigging() {
    final memory = _targetMemory!;
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B3E).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text("発掘に成功しました！", style: TextStyle(color: Colors.cyan, fontSize: 18)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IceEffects.memoryDetailContent(memory),
                const SizedBox(height: 24),
                const Text("心に触れたら、言葉と光を贈りましょう", 
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLength: 20,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.cyan,
                  decoration: InputDecoration(
                    hintText: "一言メッセージ（任意）",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.cyan, width: 1),
                    ),
                    counterStyle: const TextStyle(color: Colors.cyan, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ), // ★ ここで SizedBox と content が正しく閉じられる必要があります
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    _sePlayer.play(AssetSource('sparkle.mp3'));
                    final commentText = commentController.text.trim();
                    
                    Navigator.pop(context);
                    setState(() {
                      _targetMemory = null;
                      _clickCount = 0; 
                      _shatterController.reset();
                    });

                    await widget.onDiscover(
                      memory, 
                      commentText.isNotEmpty ? commentText : null, 
                      true
                    );

                    _showCelebration(); 
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("キラキラと想いを贈る", 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan, 
                    foregroundColor: Colors.black, 
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() {
                      _targetMemory = null;
                      _clickCount = 0; 
                      _shatterController.reset();
                    });
                    await widget.onDiscover(memory, null, false);
                  },
                  child: const Text("贈らずに自分のコレクションへ", 
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showCelebration() {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => SuccessSparkleOverlay(
        onFinished: () => overlayEntry.remove(),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
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
                          onPressed: () {
                            final diff = _calculateDifficulty(memory.createdAt);
                            setState(() { 
                              _targetMemory = memory; 
                              _clickCount = 0; 
                              _targetIceIndex = index; 
                              _calculatedRequiredClicks = diff;
                            });
                          },
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

// -------------------------------------------------------------------------
// 以下の演出ウィジェットもすべて保持（変更なし）
// -------------------------------------------------------------------------

class SuccessSparkleOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  const SuccessSparkleOverlay({super.key, required this.onFinished});

  @override
  State<SuccessSparkleOverlay> createState() => _SuccessSparkleOverlayState();
}

class _SuccessSparkleOverlayState extends State<SuccessSparkleOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SparklePoint> _sparkles = List.generate(45, (index) => SparklePoint());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Container(color: Colors.black.withOpacity((1.0 - _controller.value).clamp(0, 0.7))),
          ),
          ..._sparkles.map((s) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Positioned(
                left: s.x * MediaQuery.of(context).size.width,
                top: (s.y - (t * s.speed)) * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: (1.0 - t).clamp(0, 1),
                  child: Icon(Icons.auto_awesome, color: s.color, size: s.size),
                ),
              );
            },
          )),
          Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                ),
                child: const Text("想いを届けました ✨",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IceShard {
  final double angle, distance, size;
  final Color color; // レア破片用の色
  IceShard({required this.angle, required this.distance, required this.size, required this.color});
}

class IceCrackPainter extends CustomPainter {
  final double progress;
  IceCrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.1) return;
    final paint = Paint()..color = Colors.white.withOpacity(0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final glowPaint = Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 4.0..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final random = Random(42); 
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    int mainCracks = (progress * 15).toInt().clamp(3, 15);
    for (int i = 0; i < mainCracks; i++) {
      final path = Path();
      path.moveTo(centerX, centerY);
      double currentX = centerX;
      double currentY = centerY;
      double angle = (i * (2 * pi / mainCracks)) + (random.nextDouble() * 0.5);
      double maxLength = (size.width / 1.5) * progress;
      int segments = 5;
      for (int j = 0; j < segments; j++) {
        double step = (maxLength / segments);
        currentX += cos(angle) * step + (random.nextDouble() - 0.5) * 20;
        currentY += sin(angle) * step + (random.nextDouble() - 0.5) * 20;
        path.lineTo(currentX, currentY);
        if (progress > 0.4 && random.nextDouble() > 0.6) {
          _drawBranch(canvas, paint, currentX, currentY, angle + 0.8, progress * 30, random);
        }
      }
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  void _drawBranch(Canvas canvas, Paint paint, double x, double y, double angle, double length, Random random) {
    final branchPath = Path();
    branchPath.moveTo(x, y);
    branchPath.lineTo(x + cos(angle) * length, y + sin(angle) * length);
    canvas.drawPath(branchPath, paint);
  }

  @override
  bool shouldRepaint(IceCrackPainter oldDelegate) => oldDelegate.progress != progress;
}