import 'dart:math'; // 粒子エフェクト用に追加
import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart';

class TopScreen extends StatelessWidget {
  const TopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000), // 漆黒
              Color(0xFF0D1B3E), // 凍土の深い青
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 背景の粒子エフェクト（機能を具体化：20個の星をランダム配置）
              ...List.generate(20, (index) => _buildParticle(context, index)),

              // メインコンテンツ
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // アプリロゴ
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyan.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.ac_unit, size: 80, color: Colors.cyan),
                    ),
                    const SizedBox(height: 30),
                    
                    // タイトルテキスト
                    const Text(
                      "Frozen Memory",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3.0,
                        fontFamily: 'Serif',
                        shadows: [
                          Shadow(color: Colors.cyan, blurRadius: 20, offset: Offset(0, 0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // キャッチコピー
                    Text(
                      "記憶は、凍土に眠る。",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 4.0,
                      ),
                    ),
                    
                    const Spacer(flex: 3),

                    // 開始ボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: OutlinedButton(
                        onPressed: () => _showSignIn(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.cyan,
                          side: const BorderSide(color: Colors.cyan, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.black.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "探索を始める",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 機能を具体化した粒子エフェクト
  Widget _buildParticle(BuildContext context, int index) {
    final random = Random(index); // インデックスをシードにして配置を固定
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final size = random.nextDouble() * 3;

    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(random.nextDouble() * 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _showSignIn(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => SignInScreen(
        onCancel: () => Navigator.pop(context),
        onSignedIn: (profile) {
          // ★ 修正：ログイン成功時、履歴をすべて消してホーム画面へ
          // これにより、ログアウト時に安全にTopScreenへ戻れるようになります
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 1000),
            ),
            (route) => false, // スタックを空にする
          );
        },
      ),
    );
  }
}