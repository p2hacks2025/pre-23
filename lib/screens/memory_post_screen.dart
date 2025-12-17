import 'dart:io';
import 'package:flutter/material.dart';
import '../models/memory.dart';

class MemoryPostScreen extends StatelessWidget {
  final List<Memory> memories;
  final Function(Memory) onTapMemory;

  const MemoryPostScreen({
    super.key,
    required this.memories,
    required this.onTapMemory,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const Center(child: Text('まだ新しい記憶はありません', style: TextStyle(color: Colors.cyan)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return GestureDetector(
          onTap: () => onTapMemory(memory),
          child: _buildMemoryCard(memory),
        );
      },
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyan.withAlpha(51)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(memory.photo),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black45,
                child: Text(
                  memory.discovered ? 'by ${memory.author}' : '???',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    return path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);
  }
}