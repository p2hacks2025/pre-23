import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class SignInScreen extends StatefulWidget {
  final Function(UserProfile) onSignedIn;
  final VoidCallback onCancel;

  const SignInScreen({
    super.key,
    required this.onSignedIn,
    required this.onCancel,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _usernameController = TextEditingController();
  final _passcodeController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isRegistering = false; // 登録モードかどうか
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final passcode = _passcodeController.text.trim();

    if (username.isEmpty || passcode.isEmpty) {
      setState(() {
        _errorMessage = 'ユーザー名とパスコードを入力してください';
        _isLoading = false;
      });
      return;
    }

    bool success;
    if (_isRegistering) {
      // 新規登録
      success = await _authService.signUp(username, passcode);
      if (!success) {
        setState(() {
          _errorMessage = 'そのユーザー名は既に使用されています';
        });
      }
    } else {
      // ログイン
      success = await _authService.signIn(username, passcode);
      if (!success) {
        setState(() {
          _errorMessage = 'ユーザー名かパスコードが間違っています。\n未登録の場合は新規登録してください。';
        });
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // 成功したらユーザー情報を取得してコールバック
      final user = await _authService.getCurrentUser();
      widget.onSignedIn(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isRegistering ? '新規登録' : 'ログイン',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passcodeController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'パスコード',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.cyan)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                    child: Text(
                      _isRegistering ? '登録して開始' : 'ログイン',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // ログイン・登録の切り替えリンク
            GestureDetector(
              onTap: () {
                setState(() {
                  _isRegistering = !_isRegistering;
                  _errorMessage = '';
                });
              },
              child: Text(
                _isRegistering
                    ? 'すでにアカウントをお持ちの方はこちら'
                    : 'アカウントをお持ちでない方はこちら（新規登録）',
                style: const TextStyle(
                  color: Colors.cyan,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}