import 'dart:io';
import 'dart:math'; 
import 'package:flutter/foundation.dart'; // ★追加: Web判定用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
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
  final AuthService _authService = AuthService(); // パスワード変更用にインスタンス化

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  void _triggerSaveNotification(String message) {
    if (!mounted) return;
    setState(() => _showSavedNotification = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSavedNotification = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B3E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.cyan, blurRadius: 10, spreadRadius: -5)],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // --- メインコンテンツ ---
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                
                // アイコン
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white10,
                  backgroundImage: _getAvatarImage(_currentProfile.avatar),
                  child: _currentProfile.avatar.isEmpty 
                      ? const Icon(Icons.person, size: 60, color: Colors.white) 
                      : null,
                ),
                
                const SizedBox(height: 24),

                // ユーザー名
                Text(
                  _currentProfile.username,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12), // 余白調整

                // 自己紹介文
                Text(
                  _currentProfile.bio.isNotEmpty ? _currentProfile.bio : '自己紹介文がありません',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),

                // 編集ボタン
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('プロフィールを編集'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),

                // ログアウトボタン
                ElevatedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _authService.signOut();
                    if (mounted) navigator.pop(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('ログアウト'),
                ),
              ],
            ),
          ),

          // --- 通知バナー ---
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
                  BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "保存しました", 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★修正: Webの場合はNetworkImage、アプリの場合はFileImageを使う
  ImageProvider? _getAvatarImage(String path) {
    if (path.isEmpty) return null;
    // Webまたはhttpで始まるURLならNetworkImage
    if (kIsWeb || path.startsWith('http')) {
      return NetworkImage(path);
    }
    // スマホアプリならFileImage
    return FileImage(File(path));
  }

  // --- パスワード変更ダイアログ ---
  void _showChangePasswordDialog(BuildContext parentContext) {
    final passwordController = TextEditingController();
    bool isObscure = true;
    String? errorMessage;

    showDialog(
      context: parentContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      errorText: errorMessage,
                      suffixIcon: IconButton(
                        icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                        onPressed: () => setStateDialog(() => isObscure = !isObscure),
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
                  child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (passwordController.text.length < 6) {
                      setStateDialog(() => errorMessage = "6文字以上で入力してください");
                      return;
                    }

                    // ダイアログのナビゲーターと、親(編集画面)のナビゲーターを取得
                    final navigator = Navigator.of(ctx); // パスワード変更ダイアログ用
                    final parentNavigator = Navigator.of(parentContext); // プロフィール編集ダイアログ用

                    try {
                      await _authService.updatePassword(passwordController.text);
                      
                      // 1. パスワード変更ダイアログを閉じる
                      navigator.pop(); 
                      
                      // 2. 親の「プロフィール編集ダイアログ」も閉じる
                      if (parentNavigator.canPop()) {
                        parentNavigator.pop();
                      }
                      
                      // 3. 成功通知を表示 (編集画面が閉じたので、通知が見えるようになります)
                      _triggerSaveNotification("パスワードを変更しました");
                      
                    } catch (e) {
                      // エラー処理
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
          }
        );
      },
    );
  }

  // --- プロフィール編集ダイアログ ---
  void _showEditDialog(BuildContext parentContext) {
    final nameController = TextEditingController(text: _currentProfile.username);
    final bioController = TextEditingController(text: _currentProfile.bio);
    
    String tempAvatarPath = _currentProfile.avatar;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> pickImage() async {
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setStateDialog(() => tempAvatarPath = image.path);
              }
            }

            void generateRandomAvatar() {
              final randomSeed = Random().nextInt(100000).toString();
              final newUrl = 'https://api.dicebear.com/7.x/bottts/png?seed=$randomSeed';
              setStateDialog(() => tempAvatarPath = newUrl);
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E2C4B),
              title: const Text('プロフィール編集', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white10,
                            backgroundImage: _getAvatarImage(tempAvatarPath),
                            child: tempAvatarPath.isEmpty 
                                ? const Icon(Icons.add_a_photo, color: Colors.white54) 
                                : null,
                          ),
                          if (tempAvatarPath.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
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
                          icon: const Icon(Icons.image, size: 16, color: Colors.cyan),
                          label: const Text("写真", style: TextStyle(color: Colors.cyan, fontSize: 12)),
                        ),
                        TextButton.icon(
                          onPressed: generateRandomAvatar,
                          icon: const Icon(Icons.casino, size: 16, color: Colors.orangeAccent),
                          label: const Text("ランダム", style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
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
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
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
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    // パスワード変更ボタン
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // ここでの context は EditDialog の context
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
                  child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
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
          }
        );
      },
    );
  }
}