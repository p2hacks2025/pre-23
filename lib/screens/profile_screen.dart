import 'package:flutter/material.dart';
//import '../services/auth_service.dart';
import '../models/user_profile.dart';
// 同じフォルダにある場合

class ProfileScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B3E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          Text(profile.username, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(profile.bio.isEmpty ? '凍土の住人' : profile.bio, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          if (profile.id == 'guest')
            ElevatedButton(
              onPressed: onRequestSignIn,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: const Size(double.infinity, 50)),
              child: const Text('ログインする', style: TextStyle(color: Colors.black)),
            ),
          const SizedBox(height: 12),
          TextButton(onPressed: onClose, child: const Text('閉じる', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }
}