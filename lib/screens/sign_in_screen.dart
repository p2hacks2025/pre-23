// lib/screens/sign_in_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Error handling用
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class SignInScreen extends StatefulWidget {
  final Function(UserProfile) onSignedIn;
  final VoidCallback onCancel;

  // ログインフォームに初期値を入れたい場合（誘導時など）
  final String? initialUsername; 

  const SignInScreen({
    super.key,
    required this.onSignedIn,
    required this.onCancel,
    this.initialUsername,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _auth = AuthService();
  
  // 入力コントローラー
  final TextEditingController _usernameController = TextEditingController(); // Email or Username
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // 登録時専用

  bool _isLoginMode = true; // ログインモードか、新規登録モードか
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null) {
      _usernameController.text = widget.initialUsername!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------
  // ロジック: ログイン実行
  // ---------------------------------------------------
  Future<void> _handleLogin() async {
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '全ての項目を入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Auth Serviceへ委譲
      final profile = await _auth.signIn(
        identifier: identifier, 
        password: password
      );

      if (profile != null && mounted) {
        widget.onSignedIn(profile);
        Navigator.of(context).pop(); // 成功したら閉じる
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // ★ここがご希望のロジック: ユーザが見つからない場合
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        _showRegisterSuggestionDialog(identifier);
      } else if (e.code == 'wrong-password') {
        setState(() => _errorMessage = 'パスワードが間違っています');
      } else {
        setState(() => _errorMessage = 'ログインエラー: ${e.message}');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------
  // ロジック: 新規登録への誘導ダイアログ
  // ---------------------------------------------------
  void _showRegisterSuggestionDialog(String inputUsername) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('アカウントが見つかりません', style: TextStyle(color: Colors.white)),
        content: Text(
          'ユーザー「$inputUsername」は存在しません。\n新規登録を行いますか？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            onPressed: () {
              Navigator.pop(ctx);
              // モードを「新規登録」に切り替え、ユーザ名をセット
              setState(() {
                _isLoginMode = false;
                _usernameController.text = inputUsername;
                _errorMessage = null;
              });
            },
            child: const Text('新規登録する', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // ロジック: 新規登録実行
  // ---------------------------------------------------
  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '全ての項目を入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _auth.signUp(
        email: email, 
        username: username, 
        password: password
      );

      if (profile != null && mounted) {
        widget.onSignedIn(profile);
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'このメールアドレスは既に使われています';
      } else if (e.code == 'username-already-in-use') {
        _errorMessage = 'このユーザー名は既に使用されています';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'パスワードは6文字以上にしてください';
      } else {
        _errorMessage = '登録エラー: ${e.message}';
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------
  // UI構築
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54, // 背景を暗くしてモーダル感
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
              boxShadow: [
                 BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // タイトル
                Text(
                  _isLoginMode ? 'ログイン' : '新規登録',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // エラー表示
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                  ),

                // フォーム: ユーザー名 (ログイン時はEmail入力も兼ねる)
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _isLoginMode ? 'ユーザー名 または メール' : 'ユーザー名',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person, color: Colors.cyan),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                  ),
                ),
                const SizedBox(height: 16),

                // フォーム: メールアドレス (新規登録時のみ表示)
                if (!_isLoginMode) ...[
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.email, color: Colors.cyan),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // フォーム: パスワード
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.lock, color: Colors.cyan),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                  ),
                ),
                const SizedBox(height: 30),

                // アクションボタン
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.cyan))
                else ...[
                  ElevatedButton(
                    onPressed: _isLoginMode ? _handleLogin : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan, 
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    child: Text(
                      _isLoginMode ? 'ログイン' : 'アカウント作成', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // モード切替ボタン
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLoginMode ? 'アカウントをお持ちでない方はこちら' : 'すでにアカウントをお持ちの方はこちら',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  
                  // キャンセル
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('閉じる', style: TextStyle(color: Colors.white30)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}