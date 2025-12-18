// lib/screens/top_screen.dart

import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart';

class TopScreen extends StatelessWidget {
  const TopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面全体
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
              // 背景の粒子エフェクト（簡易的な星空のような点）
              ...List.generate(20, (index) => _buildParticle(context)),

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
                        fontFamily: 'Serif', // 明朝体っぽいフォントがあれば指定
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

  // 簡易的な背景の点（装飾）
  Widget _buildParticle(BuildContext context) {
    // ※本来は乱数で位置を決めますが、簡易的に固定配置の例です
    // ランダム配置にするには Random() を使うと良いです
    return const SizedBox.shrink(); 
  }

  // サインイン画面を表示する処理
  void _showSignIn(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // SignInScreenが背景色を持っているので透明に
      builder: (context) => SignInScreen(
        onCancel: () => Navigator.pop(context), // キャンセルしたら閉じるだけ
        onSignedIn: (profile) {
          // ログイン完了時の処理
          
          // 1. まずホーム画面へ遷移（フェードアニメーション付き）
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 1000), // ゆっくり遷移
            ),
          );
        },
      ),
    );
  }
}