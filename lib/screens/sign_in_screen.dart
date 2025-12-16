import 'package:flutter/material.dart';
import '../services/auth_service.dart';
//import '../models/game.dart';
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

  Future<void> _signInAnonymously() async {
    setState(() => _loading = true);
    final profile = await _auth.signInAnonymously();
    if (!mounted) return;
    widget.onSignedIn(profile);
  }

  Future<void> _signInWithName() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ユーザー名を入力してください')));
      return;
    }
    setState(() => _loading = true);
    final profile = await _auth.signInWithUsername(name);
    if (!mounted) return;
    widget.onSignedIn(profile);
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('サインイン', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'ユーザー名（任意）'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _signInWithName,
                child: const Text('ユーザー名でサインイン'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _signInAnonymously,
                child: const Text('匿名で続ける'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : widget.onCancel,
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
