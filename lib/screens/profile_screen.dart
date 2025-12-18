// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart'; // ログアウト用に必要

class ProfileScreen extends StatelessWidget {
  final UserProfile profile;
  final Function(UserProfile) onSave; // 編集保存用
  final VoidCallback onClose;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService(); // サービス呼出

    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // 少し高さを広げる
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B3E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.cyan, blurRadius: 10, spreadRadius: -5)],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // 引っ張り棒（モーダルらしさ）
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          
          // アイコン
          CircleAvatar(
            radius: 50,
            backgroundImage: profile.avatar.isNotEmpty ? NetworkImage(profile.avatar) : null,
            backgroundColor: Colors.white10,
            child: profile.avatar.isEmpty 
                ? const Icon(Icons.person, size: 50, color: Colors.white) 
                : null,
          ),
          const SizedBox(height: 24),

          // ユーザー名
          Text(
            profile.username,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // 自己紹介
          Text(
            profile.bio.isNotEmpty ? profile.bio : '自己紹介文がありません',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),

          // 編集ボタン（実装は後回しでもOKですが配置だけ）
          OutlinedButton.icon(
            onPressed: () {
               // ここに編集ダイアログを開く処理を入れる
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('編集機能は準備中です')));
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('プロフィールを編集'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),

          // ★ ログアウトボタン
          ElevatedButton.icon(
            onPressed: () async {
              // 1. ログアウト実行
              await auth.signOut();
              // 2. このモーダルを閉じる
              if (context.mounted) {
                Navigator.pop(context); 
              }
              // ※ main.dartが検知してTopScreenに戻してくれるので遷移処理は不要
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2), // 赤っぽく警告色
              foregroundColor: Colors.redAccent,
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}