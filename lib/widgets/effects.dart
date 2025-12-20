import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/memory.dart';

class IceEffects {
  static const List<String> iceImages = [
    'assets/icefilter1.png',
    'assets/icefilter2.jpg',
    'assets/icefilter3.jpg',
  ];

  static BoxDecoration glassStyle = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
    image: DecorationImage(
      image: AssetImage(iceImages[0]), 
      fit: BoxFit.cover,
      opacity: 0.25,
      colorFilter: const ColorFilter.mode(Color(0xFF1E293B), BlendMode.multiply),
    ),
    color: const Color(0xFF1E293B),
  );

  static DecorationImage getIceDecoration(int index, {double opacity = 0.6}) {
    return DecorationImage(
      image: AssetImage(iceImages[index % iceImages.length]),
      fit: BoxFit.cover,
      opacity: opacity,
      onError: (exception, stackTrace) => debugPrint('Missing: ${iceImages[index % iceImages.length]}'),
    );
  }

  static void showIceDialog({required BuildContext context, required Widget child}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: glassStyle.copyWith(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF0D1B3E).withOpacity(0.9),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  // ★ 修正ポイント：投稿者の表示をよりコンセプト（記憶のプレゼント）に寄せる
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
        Text(
          memory.text, 
          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, letterSpacing: 0.5)
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            // 投稿者の表示を「誰か」から「記憶の主」というニュアンスに
            const Icon(Icons.auto_awesome_motion, color: Colors.cyanAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              "この記憶の主: ${memory.author}", 
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w500)
            ),
            const Spacer(),
            const Icon(Icons.history, color: Colors.white38, size: 14),
            const SizedBox(width: 4),
            Text(
              '${memory.digCount}回 発掘されました', 
              style: const TextStyle(color: Colors.white38, fontSize: 11)
            ),
          ],
        ),
        if (showReactions) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10, height: 1),
          ),
          const Center(
            child: Text(
              "この記憶に、光の粒を贈る", 
              style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)
            )
          ),
          const SizedBox(height: 15),
          Center(
            child: InkWell(
              onTap: onReaction,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: Colors.cyan.withOpacity(0.1),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3))
                ),
                child: const Text("✨", style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
        ]
      ],
    );
  }
}

class SparklePoint {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double size = Random().nextDouble() * 10 + 6;
  Color color = [
    Colors.cyanAccent, 
    Colors.white, 
    Colors.blueAccent, 
    Colors.yellowAccent
  ][Random().nextInt(4)];
  double speed = Random().nextDouble() * 0.3 + 0.2;
}