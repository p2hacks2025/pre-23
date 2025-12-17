// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // FlutterFire CLIで生成されたファイル
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ★ 修正ポイント: 
    // Firebaseがまだ初期化されていない場合のみ初期化を実行します。
    // これにより "A Firebase App named [DEFAULT] already exists" エラーを防げます。
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      debugPrint('🔥 Firebase is already initialized');
    }
  } catch (e) {
    debugPrint('🔥 Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Digging App',
      // アプリ全体のテーマ設定（必要に応じて調整してください）
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark, // 永久凍土の世界観に合わせてダークモードにしています
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}