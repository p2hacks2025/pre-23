import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/memory.dart';

class IceEffects {
  static BoxDecoration glassStyle = BoxDecoration(
    color: const Color(0xFF1E293B).withOpacity(0.9),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white10, width: 0.5),
  );

  static void showIceDialog({required BuildContext context, required Widget child}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B3E).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  // スタンプカウンター（✨と数字のみを表示）
  static Widget buildStampCounter(String emoji, int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ★修正：✨1種類にするため、onReaction を引数なしの VoidCallback? に戻し、文字を削除
  static Widget memoryDetailContent(Memory memory, {bool showReactions = false, VoidCallback? onReaction}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            image: memory.photo.startsWith('http') || kIsWeb 
              ? NetworkImage(memory.photo) 
              : FileImage(File(memory.photo)) as ImageProvider, 
            fit: BoxFit.cover
          ),
        ),
        const SizedBox(height: 16),
        Text(memory.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.person, color: Colors.cyan, size: 14),
            const SizedBox(width: 4),
            Text(memory.author, style: const TextStyle(color: Colors.cyan, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.blur_on, color: Colors.white38, size: 14),
            const SizedBox(width: 4),
            Text('${memory.digCount} Digs', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        if (showReactions) ...[
          const Divider(color: Colors.white10, height: 30),
          const Center(
            child: Text("想いを送る", style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          Center(
            child: InkWell(
              onTap: onReaction,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: const Text("✨", style: TextStyle(fontSize: 45)), // ★文字なし、✨のみ
              ),
            ),
          ),
        ]
      ],
    );
  }
}