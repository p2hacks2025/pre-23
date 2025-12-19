import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// ★ 必要なモデルとサービスをインポート
import '../models/memory.dart'; 
import '../services/api_service.dart'; 
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;
  final VoidCallback onClose;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _currentProfile;
  bool _showSavedNotification = false;
  String _notificationMessage = "保存しました";
  final AuthService _authService = AuthService();
  // ★ APIサービスを初期化
  final ApiService _api = ApiService(); 

  final String _placeholderAsset = 'lib/assets/avatar_placeholder.png';

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  void _triggerSaveNotification(String message) {
    if (!mounted) return;
    setState(() {
      _notificationMessage = message;
      _showSavedNotification = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSavedNotification = false);
      }
    });
  }

  // ★ 削除ロジックを本物のデータ（Memory型）に対応
  void _showDeleteConfirmDialog(Memory memory) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2C4B),
          title: const Text('記憶の削除', style: TextStyle(color: Colors.white)),
          content: const Text(
            'この投稿を削除してもよろしいですか？\n一度削除すると元に戻せません。',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                // ★ Firestoreから削除を実行
                await _api.deleteMemory(memory.id); 
                if (mounted) Navigator.pop(ctx);
                _triggerSaveNotification("投稿を削除しました");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
              ),
              child: const Text('削除する', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B3E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.cyan, blurRadius: 10, spreadRadius: -5)
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),

                  _buildSafeAvatar(_currentProfile.avatar, 100),

                  const SizedBox(height: 16),

                  Text(
                    _currentProfile.username,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _currentProfile.bio.isNotEmpty
                        ? _currentProfile.bio
                        : '自己紹介文がありません',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // ★ ここを変更: 左にログアウト、右に編集
                  Row(
                    children: [
                      // 左: ログアウトボタン
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await _authService.signOut();
                            if (mounted) navigator.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.2),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('ログアウト'),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 右: 編集ボタン
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditDialog(context),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('編集'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "封印した記憶たち",
                      style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ★ Firestore ストリームで自分の投稿を表示
                  StreamBuilder<List<Memory>>(
                    stream: _api.watchAllMemories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // 自分の投稿（authorIdが一致するもの）だけをフィルタリング
                      final myPosts = (snapshot.data ?? [])
                          .where((m) => m.authorId == _currentProfile.id)
                          .toList();

                      if (myPosts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("まだ投稿はありません",
                              style: TextStyle(color: Colors.white38)),
                        );
                      }

                      return ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: myPosts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildPostItem(myPosts[index]);
                        },
                      );
                    }
                  ),
                ],
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            top: _showSavedNotification ? 30 : -100,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _notificationMessage,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 引数を Memory 型に変更
  Widget _buildPostItem(Memory post) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.black26,
              child: _getPostImage(post.photo), // post['imagePath'] から photo に変更
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.text, // post['comment'] から text に変更
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    post.starRating, // stars から starRating に変更
                    (i) => const Icon(Icons.star, size: 14, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: const Color(0xFF1E2C4B),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmDialog(post); // 引数を変更
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeAvatar(String path, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white10,
      ),
      clipBehavior: Clip.antiAlias,
      child: _getImageWidget(path),
    );
  }

  Widget _getImageWidget(String path) {
    if (path.isEmpty) {
      return const Icon(Icons.person, size: 50, color: Colors.white);
    }

    Widget errorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
      return Image.asset(_placeholderAsset, fit: BoxFit.cover);
    }

    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: errorWidget,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey));
        },
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, errorBuilder: errorWidget);
    } else {
      return Image.asset(_placeholderAsset, fit: BoxFit.cover);
    }
  }

  Widget _getPostImage(String path) {
    if (path.isEmpty) {
      return const Icon(Icons.image_not_supported, color: Colors.white24);
    }
    
    Widget errorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
      return Image.asset(_placeholderAsset, fit: BoxFit.cover);
    }

    if (kIsWeb || path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: errorWidget);
    }
    
    File file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, errorBuilder: errorWidget);
    }
    return Image.asset(_placeholderAsset, fit: BoxFit.cover);
  }

  void _showChangePasswordDialog(BuildContext parentContext) {
    final passwordController = TextEditingController();
    bool isObscure = true;
    String? errorMessage;

    showDialog(
      context: parentContext,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2C4B),
            title: const Text('パスワード変更', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: isObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '新しいパスワード',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    errorText: errorMessage,
                    suffixIcon: IconButton(
                      icon: Icon(
                          isObscure ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54),
                      onPressed: () =>
                          setStateDialog(() => isObscure = !isObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "※セキュリティのため、再ログインが必要になる場合があります。",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (passwordController.text.length < 6) {
                    setStateDialog(() => errorMessage = "6文字以上で入力してください");
                    return;
                  }
                  final navigator = Navigator.of(ctx);
                  final parentNavigator = Navigator.of(parentContext);
                  try {
                    await _authService.updatePassword(passwordController.text);
                    navigator.pop();
                    if (parentNavigator.canPop()) {
                      parentNavigator.pop();
                    }
                    _triggerSaveNotification("パスワードを変更しました");
                  } catch (e) {
                    setStateDialog(() {
                      errorMessage = "変更に失敗しました。\n一度ログアウトして再試行してください。";
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: const Text('変更', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditDialog(BuildContext parentContext) {
    final nameController =
        TextEditingController(text: _currentProfile.username);
    final bioController = TextEditingController(text: _currentProfile.bio);

    String tempAvatarPath = _currentProfile.avatar;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> pickImage() async {
            final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              setStateDialog(() => tempAvatarPath = image.path);
            }
          }

          void generateRandomAvatar() {
            final randomSeed = Random().nextInt(100000).toString();
            final newUrl =
                'https://api.dicebear.com/7.x/bottts/png?seed=$randomSeed';
            setStateDialog(() => tempAvatarPath = newUrl);
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E2C4B),
            title:
                const Text('プロフィール編集', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ★ ここも安全なアバター表示メソッドを使用
                        _buildSafeAvatar(tempAvatarPath, 80),
                        
                        // 編集アイコンのオーバーレイ
                        if (tempAvatarPath.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(50)),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 16),
                          ),
                         if (tempAvatarPath.isEmpty)
                          const Positioned.fill(
                             child: Icon(Icons.add_a_photo, color: Colors.white54)
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image,
                            size: 16, color: Colors.cyan),
                        label: const Text("写真",
                            style: TextStyle(color: Colors.cyan, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: generateRandomAvatar,
                        icon: const Icon(Icons.casino,
                            size: 16, color: Colors.orangeAccent),
                        label: const Text("ランダム",
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ユーザー名',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '自己紹介',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        _showChangePasswordDialog(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                      child: const Text("パスワードを変更する"),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final updatedProfile = UserProfile(
                    id: _currentProfile.id,
                    username: nameController.text.trim(),
                    bio: bioController.text.trim(),
                    avatar: tempAvatarPath,
                  );
                  await widget.onSave(updatedProfile);
                  if (!mounted) return;
                  setState(() {
                    _currentProfile = updatedProfile;
                  });
                  navigator.pop();
                  _triggerSaveNotification("保存しました");
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: const Text('保存', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        });
      },
    );
  }
}