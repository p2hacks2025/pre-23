import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../models/comment.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import 'dart:ui'; // ★ これを追加

class MemoryPostScreen extends StatefulWidget {
  final List<Memory> memories;
  final Function(String memoryId, String text, String author) onAddComment;
  final Function(Memory) onEditMemory;
  final Function(String) onDeleteMemory;
  final Function(Memory) onTapMemory; // ★これを追加

  const MemoryPostScreen({
    super.key,
    required this.memories,
    required this.onAddComment,
    required this.onEditMemory,
    required this.onDeleteMemory,
    required this.onTapMemory, // ★これを追加
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,          // 2列にする
        crossAxisSpacing: 16,       // 横の間隔
        mainAxisSpacing: 16,        // 縦の間隔
        childAspectRatio: 0.75,     // カードの縦横比（調整可能）
      ),
      itemCount: widget.memories.length,
      itemBuilder: (context, index) {
  final memory = widget.memories[index];
  return GestureDetector(
    onTap: () {
  if (memory.discovered) {
    // 発掘済みならリアクション・詳細ダイアログを表示
    _showReactionDialog(context, memory);
  } else {
    // 未発掘なら親から渡された onTapMemory（ゲーム開始など）を実行
    widget.onTapMemory(memory);
  }
},
    child: _buildMemoryCard(memory),
  );
},
    );
  }

  Widget _buildMemoryCard(Memory memory) {
  return Container(
    margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.black26, // 下地の色
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: memory.discovered 
            ? Colors.cyan.withAlpha(80) 
            : Colors.white10
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 写真
          memory.photo.startsWith('http')
              ? Image.network(memory.photo, fit: BoxFit.cover)
              : Image.file(File(memory.photo), fit: BoxFit.cover),

          // 未発掘時の氷エフェクト
          if (!memory.discovered)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.15),
                  child: const Center(
                    child: Icon(Icons.ac_unit, size: 30, color: Colors.white54),
                  ),
                ),
              ),
            ),

          // 下部のテキスト情報（発見済みのみ表示してスッキリさせるのもアリ）
          if (memory.discovered)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.black54,
                child: Text(
                  memory.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// 通知を送るロジック（将来的にここにFirebaseなどを繋ぎます）
  void _sendNotificationToAuthor(String emoji, String? authorId) {
    if (authorId == null || authorId.isEmpty) return;
    // ここでサーバーやFirebaseに「通知リクエスト」を送る処理を記述します
    debugPrint('通知リクエスト送信: 投稿主 $authorId へ $emoji');
  }

  // 発掘成功時または詳細タップ時に呼び出す
  void _showReactionDialog(BuildContext context, Memory memory) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.cyan.shade900.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('記憶へのリアクション', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18)),
      // ★ ここに SingleChildScrollView を追加して、はみ出しを防ぐ
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: memory.photo.startsWith('http')
                    ? Image.network(memory.photo, fit: BoxFit.cover)
                    : Image.file(File(memory.photo), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Text('by ${memory.author}', style: const TextStyle(color: Colors.cyan, fontSize: 12)),
            const SizedBox(height: 4),
            Text(memory.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 16),
            // スタンプ部分のパディングを少し削る
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stampButton(context, '❤️', '共感', memory.authorId),
                _stampButton(context, '✨', '感動', memory.authorId),
                _stampButton(context, '❄️', '美しい', memory.authorId),
                _stampButton(context, '🙏', '感謝', memory.authorId),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _stampButton(BuildContext context, String emoji, String label, String? authorId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            _sendNotificationToAuthor(emoji, authorId);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.cyan.shade700,
                content: Text('投稿主に $emoji を届けました'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  // 詳細表示（いいね・コメント）用のボトムシートを表示する
  void _showMemoryDetails(BuildContext context, Memory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 画面の高さに合わせて調整
      backgroundColor: Colors.transparent, // 背景を透明にしてカスタムデザインを活かす
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.cyan.shade900.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.cyan.withAlpha(100)),
        ),
        child: Column(
          children: [
            // 上部の「引き出し」用バー
            Container(
              margin: const EdgeInsets.all(12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 写真
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: memory.photo.startsWith('http')
                          ? Image.network(memory.photo, fit: BoxFit.cover)
                          : Image.file(File(memory.photo), fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),

                    // アクションエリア（いいね）
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // ここで「いいね」の処理（スナックバー表示例）
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('記憶に共感しました！')),
                            );
                          },
                          icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                          label: const Text('共感する'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.history, color: Colors.cyan, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy/MM/dd').format(memory.createdAt),
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    
                    // 本文
                    Text(
                      memory.text,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 24),

                    // コメントセクション
                    const Text(
                      'コメント',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...memory.comments.map((c) => _buildComment(c)),
                    const SizedBox(height: 12),
                    _buildCommentForm(memory.id),
                    // キーボードで隠れないように余白を追加
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
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

