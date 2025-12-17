import 'package:flutter/material.dart';
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
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _loading = false;

  // 匿名サインイン
  Future<void> _signInAnonymously() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final profile = await _auth.signInAnonymously();
      if (!mounted) return;
      
      // ★ 修正: まずダイアログを閉じる
      Navigator.of(context).pop();
      
      // 親画面に通知
      widget.onSignedIn(profile);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('サインイン失敗: $e'))
        );
      }
    }
  }

  // 名前指定サインイン
  Future<void> _signInWithName() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ユーザー名を入力してください')));
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final profile = await _auth.signInWithUsername(name);
      if (!mounted) return;
      
      // ★ 修正: まずダイアログを閉じる
      Navigator.of(context).pop();
      
      widget.onSignedIn(profile);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('サインイン失敗: $e'))
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'サインイン',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ユーザー名（任意）',
                  labelStyle: const TextStyle(color: Colors.cyan),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: Colors.cyan))
              else ...[
                ElevatedButton(
                  onPressed: _signInWithName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ユーザー名でサインイン', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _signInAnonymously,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyan,
                    side: const BorderSide(color: Colors.cyan),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('匿名で続ける'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}