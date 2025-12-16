// lib/main.dart

// 必要なインポート
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 💡 このインポートが必要です
import 'firebase_options.dart'; // 💡 firebase_options.dartをインポート
import 'screens/home_screen.dart'; 
// ... 他のインポート

// main関数を async にし、Firebaseを初期化します
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Firebaseの初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // 2. 初期化エラーのデバッグ出力
    // このエラーが出ている場合は、WindowsのFirebase設定が不完全である可能性が高い
    debugPrint('🔥 Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      home: const HomeScreen(),
    );
  }
}