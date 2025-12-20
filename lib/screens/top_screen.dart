import 'dart:math';
import 'dart:ui'; // ぼかしエフェクト（氷の質感）に必要
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart';

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 輝きや粒子のゆらぎを制御する無限アニメーション
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 背景：深い凍土のグラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.5,
                colors: [
                  Color(0xFF1E3A5F), // 氷の奥底の青
                  Color(0xFF000000), // 完全な静寂
                ],
              ),
            ),
          ),

          // 2. 粒子エフェクト：氷の粉（ダイヤモンドダスト）
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: List.generate(40, (index) => _buildSparkle(context, index)),
              );
            },
          ),

          // 3. メインコンテンツ
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  
                  // アプリロゴ：氷の結晶と光輪
                  _buildIceCrystalLogo(),
                  
                  const SizedBox(height: 40),
                  
                  // タイトル：思い出が凍っているイメージ（文字間隔を広く）
                  const Text(
                    "FROZEN MEMORY",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w200, // 細字で透明感を演出
                      color: Colors.white,
                      letterSpacing: 10.0,
                      shadows: [
                        Shadow(color: Colors.cyanAccent, blurRadius: 20),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // キャッチコピー
                  Text(
                    "思い出は、光となって凍土に眠る。",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 4.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  const Spacer(flex: 4),

                  // 4. 開始ボタン：氷を削り出したような「グラスモーフィズム」デザイン
                  _buildIceButton(context),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 氷の結晶ロゴ：複数の光を重ねて「キラキラ」を表現
  Widget _buildIceCrystalLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背後の光輪
        ...List.generate(2, (i) => Transform.rotate(
          angle: _controller.value * pi * (i == 0 ? 1 : -1),
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyan.withOpacity(0.1), width: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        )),
        // 結晶アイコン
        const Icon(Icons.ac_unit, size: 80, color: Colors.white),
        Icon(Icons.ac_unit, size: 85, color: Colors.cyanAccent.withOpacity(0.3)),
      ],
    );
  }

  // 氷のボタン：背景をぼかすことで「氷の質感」を出す
  Widget _buildIceButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 強いぼかし
        child: Container(
          width: 280,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
          ),
          child: InkWell(
            onTap: () => _showSignIn(context),
            child: const Center(
              child: Text(
                "探索を始める",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // キラキラと舞う粒子（ダイヤモンドダスト）
  Widget _buildSparkle(BuildContext context, int index) {
    final random = Random(index);
    final size = random.nextDouble() * 3 + 10;
    final baseTop = random.nextDouble() * MediaQuery.of(context).size.height;
    final baseLeft = random.nextDouble() * MediaQuery.of(context).size.width;
    
    // アニメーションに合わせてゆっくりゆらぐ
    final drift = sin(_controller.value * pi * 2 + index) * 20;

    return Positioned(
      top: baseTop + drift,
      left: baseLeft + (drift * 0.5),
      child: Opacity(
        opacity: (sin(_controller.value * pi * 2 + index) + 1) / 2 * 0.6, // 明滅
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: index % 3 == 0 ? Colors.cyanAccent : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 5),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignIn(BuildContext context) {
    // 既存の機能を維持
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => SignInScreen(
        onCancel: () => Navigator.pop(context),
        onSignedIn: (profile) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, anim, secAnim) => const HomeScreen(),
              transitionsBuilder: (context, anim, secAnim, child) {
                return FadeTransition(opacity: anim, child: child);
              },
              transitionDuration: const Duration(milliseconds: 1500),
            ),
            (route) => false,
          );
        },
      ),
    );
  }
}