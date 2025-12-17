// lib/widgets/memory_list_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/memory.dart';

enum MemoryListType {
  discovery, // 大きなカード表示 (タイムライン風)
  grid,      // グリッド表示 (マイページ・コレクション用)
}

class MemoryListView extends StatelessWidget {
  final List<Memory> memories;
  final MemoryListType type;
  final Function(Memory) onTapMemory;
  final Function(String)? onDeleteMemory; // 削除機能は必要な場合のみ渡す

  const MemoryListView({
    super.key,
    required this.memories,
    required this.onTapMemory,
    this.type = MemoryListType.grid,
    this.onDeleteMemory,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ac_unit, size: 64, color: Colors.cyan.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'まだ記憶は凍土に眠っていません',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // タイプによって表示を切り替え
    if (type == MemoryListType.discovery) {
      return _buildDiscoveryList();
    } else {
      return _buildGridList();
    }
  }

  // 旧 DiscoveryScreen の見た目
  Widget _buildDiscoveryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return GestureDetector(
          onTap: () => onTapMemory(memory),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A4A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildImage(memory.photo),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('by ${memory.author}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                          Text(
                            "${memory.createdAt.year}/${memory.createdAt.month}/${memory.createdAt.day}",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        memory.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 旧 MyMemoryListScreen / MemoryPostScreen の見た目
  Widget _buildGridList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return GestureDetector(
          onTap: () {
            // 削除機能が有効なら削除確認、そうでなければ詳細表示
            if (onDeleteMemory != null) {
              _showDeleteConfirm(context, memory.id);
            } else {
              onTapMemory(memory);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(memory.photo),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Text(
                        memory.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey);
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }

  void _showDeleteConfirm(BuildContext context, String memoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B3E),
        title: const Text('記憶の消去', style: TextStyle(color: Colors.white)),
        content: const Text('この記憶を永久に消去しますか？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (onDeleteMemory != null) onDeleteMemory!(memoryId);
              Navigator.pop(context);
            },
            child: const Text('消去', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}