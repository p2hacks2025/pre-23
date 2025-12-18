// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Authを使う
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/top_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('🔥 Firebase initialization failed: $e');
    }
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
      // ★ ここが重要：StreamBuilderでログイン状態を監視する
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. 読み込み中ならローディング画面（真っ黒でOK）
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 2. ユーザーが存在する（ログイン済み）なら -> ホーム画面へ
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // 3. ユーザーがいない（未ログイン）なら -> トップ画面へ
          return const TopScreen();
        },
      ),
    );
  }
}