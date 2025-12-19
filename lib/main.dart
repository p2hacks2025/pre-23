// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ★追加
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/top_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase初期化
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('🔥 Firebase initialization failed: $e');
    }
  }

  // ★追加: App Checkの初期化
  // これにより "No AppCheckProvider installed" エラーが解消されます
  try {
    await FirebaseAppCheck.instance.activate(
      // Androidエミュレータや開発ビルド用には debug プロバイダを使用
      androidProvider: AndroidProvider.debug,
      // iOSシミュレータ用
      appleProvider: AppleProvider.debug,
    );
    debugPrint('✅ App Check activated');
  } catch (e) {
    debugPrint('⚠️ App Check activation failed: $e');
  }

  // Auth設定
  try {
    // テスト用にSMS検証などを無効化（既存のコード）
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
    
    // ★追加: 言語コードを日本語に設定
    // これにより "X-Firebase-Locale ... null" 警告が解消されます
    await FirebaseAuth.instance.setLanguageCode('ja'); 
    
    debugPrint('✅ Auth settings applied: verification disabled & language set to ja');
  } catch (e) {
    debugPrint('⚠️ Failed to set auth settings: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frozen Memory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B3E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
        ),
      ),
      // ログイン状態を監視して画面を切り替え
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const TopScreen();
        },
      ),
    );
  }
}