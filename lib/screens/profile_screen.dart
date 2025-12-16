// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
//import '../services/auth_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onSave;
  final VoidCallback onClose;
  final VoidCallback onRequestSignIn;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onClose,
    required this.onRequestSignIn,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // キーボードが出ているかどうかの高さ取得
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: const Color(0xFF1a1a1a), // 背景色（ダークモード風）
      // ★ ここが重要：高さ制限を画面の90%くらいにする設定
      height: MediaQuery.of(context).size.height * 0.9,
      
      child: Column(
        children: [
          // 上部のドラッグ用ハンドル
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // ★ ここから下をスクロール可能にする
          Expanded(
            child: SingleChildScrollView(
              // ★ キーボードが出た時に隠れないようにパディングを入れる
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'プロフィール設定',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan[100],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ユーザー名
                  Text('コードネーム (ユーザー名)', style: TextStyle(color: Colors.cyan[200], fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.cyan.withAlpha(100)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.cyan.withAlpha(50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 自己紹介
                  Text('記録 (自己紹介)', style: TextStyle(color: Colors.cyan[200], fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 4, // 複数行入力
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.cyan.withAlpha(100)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.cyan.withAlpha(50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_usernameController.text.trim().isEmpty) return;
                        
                        final updatedProfile = UserProfile(
                          id: widget.profile.id,
                          username: _usernameController.text.trim(),
                          avatar: widget.profile.avatar,
                          bio: _bioController.text.trim(),
                        );
                        widget.onSave(updatedProfile);
                        widget.onClose();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('情報を更新', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  // ゲストの場合のサインイン誘導などがあればここに
                  if (widget.profile.id == 'guest') ...[
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: widget.onRequestSignIn,
                        child: const Text('正式なアカウントでログイン', style: TextStyle(color: Colors.cyan)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}