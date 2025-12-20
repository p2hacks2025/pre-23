import 'dart:io';
import 'package:flutter/material.dart';
import '../models/memory.dart';

class MyMemoryListScreen extends StatelessWidget {
  final List<Memory> memories;
  final Function(String) onDeleteMemory;
  final Function(Memory) onShowDetail;

  // ★ ダミーの代替画像パス (lib/assets直下)
  final String _placeholderAsset = 'lib/assets/avatar_placeholder.png';

  const MyMemoryListScreen({
    super.key,
    required this.memories,
    required this.onDeleteMemory,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ac_unit, size: 64, color: Colors.cyan.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'まだあなたの記憶は凍土に眠っていません', 
              style: TextStyle(color: Colors.white54, fontSize: 14)
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return _buildMemoryItem(context, memory);
      },
    );
  }

  Widget _buildMemoryItem(BuildContext context, Memory memory) {
    // エラー時のフォールバック関数
    Widget errorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
      return Image.asset(_placeholderAsset, fit: BoxFit.cover);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 背景画像とタップイベント
            Positioned.fill(
              child: GestureDetector(
                onTap: () => onShowDetail(memory),
                child: Hero(
                  tag: 'memory-${memory.id}',
                  // ★ ネット画像でも安全に表示するロジック
                  child: memory.photo.startsWith('http')
                      ? Image.network(
                          memory.photo,
                          fit: BoxFit.cover,
                          errorBuilder: errorWidget,
                        )
                      : Image.file(
                          File(memory.photo),
                          fit: BoxFit.cover,
                          errorBuilder: errorWidget,
                        ),
                ),
              ),
            ),
            // グラデーションオーバーレイ
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
            ),
            // 削除ボタン
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                onPressed: () => _confirmDelete(context, memory.id),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
            // リアクション数表示
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.cyanAccent),
                  const SizedBox(width: 4),
                  Text(
                    '${memory.comments.length}',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '記憶の消去', 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),
            const Text(
              '一度消去した記憶は二度と戻りません。\n本当によろしいですか？', 
              style: TextStyle(color: Colors.white70), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('残す', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onDeleteMemory(id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('消去する'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}