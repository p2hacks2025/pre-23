import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// 同じフォルダにある場合

class CreateMemoryScreen extends StatefulWidget {
  // ★ starRatingを引数に追加するように修正
  final Function(String photo, String text, String author, int starRating) onSubmit;
  final VoidCallback onCancel;
  final String? initialAuthor;

  const CreateMemoryScreen({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.initialAuthor,
  });

  @override
  State<CreateMemoryScreen> createState() => _CreateMemoryScreenState();
}

class _CreateMemoryScreenState extends State<CreateMemoryScreen> {
  XFile? _selectedImage;
  final _textController = TextEditingController();
  late TextEditingController _authorController;
  final ImagePicker _picker = ImagePicker();
  
  // ★ キラキラ度の状態をこちらで管理
  int _starRating = 1;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _authorController = TextEditingController(text: widget.initialAuthor ?? '');
  }

  void _submit() {
    if (_selectedImage != null &&
        _textController.text.trim().isNotEmpty &&
        _authorController.text.trim().isNotEmpty) {
      // ★ 引数に _starRating を追加
      widget.onSubmit(
        _selectedImage!.path,
        _textController.text.trim(),
        _authorController.text.trim(),
        _starRating,
      );
      setState(() {
        _selectedImage = null;
        _textController.clear();
        _authorController.clear();
        _starRating = 1; // リセット
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのフィールドを入力してください')),
      );
    }
  }

  void submitForm() {
    _submit();
  }

  // ★ 星を選択するUIウィジェット
  Widget _buildStarRating() {
    return Column(
      children: [
        const Text(
          'キラキラ度',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            int starValue = index + 1;
            return IconButton(
              icon: Icon(
                starValue <= _starRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 40,
              ),
              onPressed: () {
                setState(() {
                  _starRating = starValue;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '記憶を永久凍土に封印',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Photo Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 256,
                decoration: BoxDecoration(
                  color: Colors.cyan.shade900.withAlpha(77),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.cyan.withAlpha(128),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Builder(builder: (context) {
                  final imagePath = _selectedImage?.path;
                  if (imagePath != null && imagePath.isNotEmpty) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => setState(() => _selectedImage = null),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload, size: 48, color: Colors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        'クリックして写真を選択',
                        style: TextStyle(color: Colors.cyan[200], fontSize: 16),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            
            // ★ キラキラ度入力UIを追加
            _buildStarRating(),
            const SizedBox(height: 24),

            // Comment Input
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'コメント',
                labelStyle: TextStyle(color: Colors.cyan[300]),
                filled: true,
                fillColor: Colors.cyan.shade900.withAlpha(128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.cyan),
                ),
              ),
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            // Author Input
            if (widget.initialAuthor == null)
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: '投稿者名',
                  labelStyle: TextStyle(color: Colors.cyan[300]),
                  filled: true,
                  fillColor: Colors.cyan.shade900.withAlpha(128),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.cyan.withAlpha(77)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '投稿者: ${widget.initialAuthor}',
                  style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.cyan.withAlpha(77)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '封印する',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }
}