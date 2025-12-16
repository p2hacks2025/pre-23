import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../models/comment.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';

class MemoryPostScreen extends StatefulWidget {
  final List<Memory> memories;
  final Function(String memoryId, String text, String author) onAddComment;
  final Function(Memory) onEditMemory;
  final Function(String) onDeleteMemory;

  const MemoryPostScreen({
    super.key,
    required this.memories,
    required this.onAddComment,
    required this.onEditMemory,
    required this.onDeleteMemory,
  });

  @override
  State<MemoryPostScreen> createState() => _MemoryPostScreenState();
}

class _MemoryPostScreenState extends State<MemoryPostScreen> {
  final Map<String, bool> _showComments = {};
  final StorageService _storage = StorageService();
  Map<String, UserProfile> _usersById = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _storage.getUsers();
    setState(() {
      _usersById = {for (var u in users) u.id: u};
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.memories.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyan.withAlpha(51)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.ac_unit, size: 64, color: Colors.cyan),
              const SizedBox(height: 16),
              const Text(
                'まだ記憶を発掘していません',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '「発掘」から凍土を掘り起こしましょう',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.cyan[300],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.memories.length,
      itemBuilder: (context, index) {
        final memory = widget.memories[index];
        return _buildMemoryCard(memory);
      },
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
              Colors.cyan.withAlpha(51),
              Colors.blue.withAlpha(51),
            ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyan.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  memory.photo.startsWith('http')
                      ? Image.network(
                          memory.photo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.cyan[900],
                              child: const Icon(Icons.image, size: 48, color: Colors.white54),
                            );
                          },
                        )
                      : Image.file(
                          File(memory.photo),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.cyan[900],
                              child: const Icon(Icons.image, size: 48, color: Colors.white54),
                            );
                          },
                        ),
                  Container(
                    decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.cyan[900]!.withAlpha(128),
                                ],
                              ),
                            ),
                  ),
                  // three-dot menu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      color: Colors.cyan.shade900,
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final textController = TextEditingController(text: memory.text);
                          final authorController = TextEditingController(text: memory.author);
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('投稿を編集'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: textController, decoration: const InputDecoration(labelText: '本文')),
                                  const SizedBox(height: 8),
                                  TextField(controller: authorController, decoration: const InputDecoration(labelText: '作者')),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('保存')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            final updated = memory.copyWith(text: textController.text.trim(), author: authorController.text.trim());
                            widget.onEditMemory(updated);
                          }
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('削除確認'),
                              content: const Text('この投稿を削除してよいですか？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('削除')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            widget.onDeleteMemory(memory.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('編集', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'delete', child: Text('削除', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // show resolved author (prefer authorId)
                    Builder(builder: (context) {
                      final user = memory.authorId != null ? _usersById[memory.authorId] : null;
                      if (user != null) {
                        return Row(
                          children: [
                            if (user.avatar.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundImage: user.avatar.startsWith('http')
                                      ? NetworkImage(user.avatar)
                                      : FileImage(File(user.avatar)) as ImageProvider,
                                ),
                              ),
                            Text(user.username, style: TextStyle(color: Colors.cyan[300], fontSize: 14)),
                          ],
                        );
                      }
                      return Text(
                        memory.author,
                        style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                      );
                    }),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.cyan),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy年MM月dd日').format(memory.createdAt),
                      style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showComments[memory.id] = !(_showComments[memory.id] ?? false);
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.comment, size: 16, color: Colors.cyan),
                      const SizedBox(width: 4),
                      Text(
                        'コメント (${memory.comments.length})',
                        style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_showComments[memory.id] ?? false) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.cyan),
                  const SizedBox(height: 12),
                  ...memory.comments.map((comment) => _buildComment(comment)),
                  const SizedBox(height: 12),
                  _buildCommentForm(memory.id),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.shade900.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.author,
                style: const TextStyle(color: Colors.cyan, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('yyyy年MM月dd日').format(comment.createdAt),
                style: TextStyle(color: Colors.cyan[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentForm(String memoryId) {
    final commentAuthorController = TextEditingController();
    final commentTextController = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: commentAuthorController,
            decoration: InputDecoration(
            labelText: '名前',
            labelStyle: TextStyle(color: Colors.cyan[300]),
            filled: true,
              fillColor: Colors.cyan.shade900.withAlpha(128),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.cyan),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentTextController,
                  decoration: InputDecoration(
                  labelText: 'コメントを書く...',
                  labelStyle: TextStyle(color: Colors.cyan[300]),
                  filled: true,
                  fillColor: Colors.cyan.shade900.withAlpha(128),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (commentTextController.text.trim().isNotEmpty &&
                    commentAuthorController.text.trim().isNotEmpty) {
                  widget.onAddComment(
                    memoryId,
                    commentTextController.text.trim(),
                    commentAuthorController.text.trim(),
                  );
                  commentTextController.clear();
                  commentAuthorController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}

