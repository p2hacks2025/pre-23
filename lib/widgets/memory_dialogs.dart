import 'dart:io';
import 'package:flutter/material.dart';
import '../models/memory.dart';

class MemoryDialogs {
  /// 自分の投稿の詳細を表示するダイアログ
  static void showDetail(BuildContext context, Memory memory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 修正: withOpacity -> withValues
        backgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.cyan, width: 0.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: memory.photo.startsWith('http')
                  ? Image.network(memory.photo)
                  : Image.file(File(memory.photo)),
            ),
            const SizedBox(height: 20),
            Text(
              memory.text,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// 他人の投稿にリアクションを送るダイアログ
  static void showReaction(BuildContext context, Memory memory, Function(String) onReactionSent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 修正: withOpacity -> withValues
        backgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.cyan, width: 0.5),
        ),
        title: const Text(
          '共感を届ける',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['❤️', '✨', '❄️', '💎'].map((emoji) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onReactionSent(emoji);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // 修正: withOpacity -> withValues
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          )).toList(),
        ),
      ),
    );
  }
}