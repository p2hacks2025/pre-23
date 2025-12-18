// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class SignInScreen extends StatefulWidget {
  final Function(UserProfile) onSignedIn;
  final VoidCallback onCancel;

  const SignInScreen({super.key, required this.onSignedIn, required this.onCancel});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // 新規登録時のみ使用
  
  final AuthService _auth = AuthService();
  
  bool _isLoading = false;
  bool _isRegisterMode = false; // 新規登録モードかどうか
  String? _errorMessage;

  // メインの処理（ログインまたは登録）
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'メールアドレスとパスワードを入力してください');
      return;
    }

    if (_isRegisterMode && _usernameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'ユーザー名を入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserProfile profile;
      
      if (_isRegisterMode) {
        // --- 新規登録処理 ---
        profile = await _auth.signUpWithEmail(
          email: email,
          password: password,
          username: _usernameController.text.trim(),
        );
      } else {
        // --- ログイン処理 ---
        try {
          profile = await _auth.signInWithEmail(email, password);
        } on FirebaseAuthException catch (e) {
          // ★ここでUX分岐: ユーザーがいない場合
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            // 最近のFirebaseは user-not-found を invalid-credential にまとめることがあります
            // 具体的な判別が難しい場合もあるため、一度登録モードへ誘導するフローにします
            setState(() {
              _isRegisterMode = true; // 登録モードへ切り替え
              _isLoading = false;
              _errorMessage = 'アカウントが見つかりません。\n新規登録しますか？ユーザー名を入力してください。';
            });
            return; // ここで中断し、ユーザーに入力を促す
          } else if (e.code == 'wrong-password') {
            throw Exception('パスワードが違います');
          } else {
            rethrow; // その他のエラーは下でキャッチ
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // ダイアログを閉じる
      widget.onSignedIn(profile); // 完了通知

    } catch (e) {
      setState(() {
        _errorMessage = _cleanErrorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // エラーメッセージを日本語化して読みやすく
  String _cleanErrorMessage(dynamic e) {
    String msg = e.toString();
    if (msg.contains('wrong-password')) return 'パスワードが間違っています';
    if (msg.contains('invalid-email')) return 'メールアドレスの形式が正しくありません';
    if (msg.contains('weak-password')) return 'パスワードは6文字以上で設定してください';
    if (msg.contains('email-already-in-use')) return 'このメールアドレスは既に登録されています';
    // prefixを除去
    return msg.replaceAll('Exception:', '').replaceAll('[firebase_auth/.*] ', '');
  }

  @override
  Widget build(BuildContext context) {
    // 背景のタップでキーボードを閉じる
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Colors.black54, // 背景を少し暗く
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 340,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3E), // アプリのテーマカラーに合わせる
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegisterMode ? '新規登録' : 'サインイン',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // エラー表示
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // メール入力
                  _buildTextField(
                    controller: _emailController,
                    label: 'メールアドレス',
                    icon: Icons.email_outlined,
                    inputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // パスワード入力
                  _buildTextField(
                    controller: _passwordController,
                    label: 'パスワード (6文字以上)',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  
                  // ★新規登録モードの時だけユーザー名入力欄が出現
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'ユーザー名 (表示名)',
                      icon: Icons.person_outline,
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.cyan))
                  else
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isRegisterMode ? '登録して始める' : 'ログイン',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.cyan.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}