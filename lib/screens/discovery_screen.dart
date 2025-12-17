import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/memory.dart';

class DiscoveryScreen extends StatelessWidget {
  final List<Memory> memories;
  final Function(Memory) onTapMemory;

  const DiscoveryScreen({
    super.key,
    required this.memories,
    required this.onTapMemory,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const Center(
        child: Text('まだ新しい記憶はありません', style: TextStyle(color: Colors.cyan)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return _buildMemoryCard(memory);
      },
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A4A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 画像セクション（AspectRatio 2.0 で高さを抑えました）
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 2.0,
                  child: _buildImage(memory.photo, memory.discovered),
                ),
              ),
              if (!memory.discovered)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => onTapMemory(memory),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B3E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 14, color: Colors.cyanAccent),
                          SizedBox(width: 8),
                          Text('発掘する', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // テキスト・統計情報セクション
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      memory.discovered ? memory.author : '未知の旅人',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(3, (i) => Icon(
                        Icons.star,
                        size: 16,
                        color: i < memory.starRating ? Colors.amber : Colors.white10,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  memory.discovered ? memory.text : '凍土に埋もれた記憶。中身を知るには発掘が必要です。',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(Icons.auto_fix_high, '4回発掘'),
                    const SizedBox(width: 20),
                    _buildStatItem(Icons.diamond_outlined, '${memory.comments.length} 共鳴'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.cyanAccent.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.cyanAccent.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }

  Widget _buildImage(String path, bool isDiscovered) {
    Widget image = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);

    if (!isDiscovered) {
      return Stack(
        fit: StackFit.expand,
        children: [
          image,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
        ],
      );
    }
    return image;
  }
}
