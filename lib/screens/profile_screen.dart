// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final bool isGuest; // ★ ゲストかどうか
  final Function(UserProfile) onSave;
  final VoidCallback onClose;
  final VoidCallback onRequestSignIn; // ★ ログイン画面呼び出し
  final VoidCallback? onSignOut;      // ★ ログアウト処理

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.isGuest,
    required this.onSave,
    required this.onClose,
    required this.onRequestSignIn,
    this.onSignOut,
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

  void _handleSave() {
    // ゲストは保存できない（念のためガード）
    if (widget.isGuest) return;

    final updatedProfile = UserProfile(
      id: widget.profile.id,
      username: _usernameController.text,
      avatar: widget.profile.avatar,
      bio: _bioController.text,
    );
    widget.onSave(updatedProfile);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    // ボトムシートの背景と形状
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 画面の85%の高さ
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        children: [
          // --- ヘッダー部分 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, height: 1),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // --- アバターアイコン ---
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                    child: Text(
                      widget.profile.username.isNotEmpty 
                          ? widget.profile.username[0].toUpperCase() 
                          : (widget.isGuest ? '?' : 'U'),
                      style: const TextStyle(
                        fontSize: 40, 
                        color: Colors.cyan, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ★ ここで分岐: ゲストかログインユーザーか
                  if (widget.isGuest) ...[
                    // --- ゲスト用表示 ---
                    const Text(
                      'ゲストとして参加中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ログインすると、以下の機能が利用できます：\n・「いいね」や「コメント」の投稿\n・プロフィールの編集\n・発掘データの保存',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // ログイン/登録ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: widget.onRequestSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ログイン / 新規登録',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // --- ログインユーザー用表示（編集可能） ---
                    
                    // ユーザー名
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'USER NAME',
                        labelStyle: TextStyle(color: Colors.cyan),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 自己紹介 (Bio)
                    TextField(
                      controller: _bioController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'BIO',
                        labelStyle: TextStyle(color: Colors.cyan),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                        hintText: '一言コメント...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 保存ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '変更を保存',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ログアウトボタン
                    TextButton.icon(
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'ログアウト',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}