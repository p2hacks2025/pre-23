import 'dart:math'; // これを追加！
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import '../models/memory.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'digging_game_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import 'create_memory_screen.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/effects.dart';

enum CurrentView { discovery, home, achievements }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  CurrentView _currentView = CurrentView.home;
  UserProfile? _userProfile;
  bool _isLoading = true;
  
  late PageController _pageController;
  late AnimationController _shimmerController;
  // ★ 追加: 背景のキラキラ用コントローラー
  late AnimationController _bgController;
  
  StreamSubscription<UserProfile?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // ★ 追加: 背景アニメーション（20秒で1周）
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((profile) {
      if (!mounted) return;

      if (profile == null) {
        // ★ 修正：Navigator操作を一切行わない
        // main.dart の StreamBuilder が自動的に TopScreen に切り替えるため、
        // ここでは状態のクリーンアップ（もし必要なら）のみに留めます。
        setState(() {
          _userProfile = null;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pageController.dispose();
    _shimmerController.dispose();
    _bgController.dispose(); // ★ 破棄を忘れずに
    super.dispose();
  }

  // --- プロフィール・投稿作成などのメソッドは変更なし（そのまま維持） ---
  void _openProfile() {
    if (_userProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileScreen(
        profile: _userProfile!,
        onClose: () => Navigator.pop(context),
        onSave: (updatedProfile) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            String finalAvatarUrl = updatedProfile.avatar;
            if (finalAvatarUrl.isNotEmpty && !finalAvatarUrl.startsWith('http')) {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('user_avatars')
                  .child('${updatedProfile.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

              if (kIsWeb) {
                await storageRef.putData(await _api.getImageBytes(finalAvatarUrl));
              } else {
                await storageRef.putFile(File(finalAvatarUrl));
              }
              finalAvatarUrl = await storageRef.getDownloadURL();
            }

            await FirebaseFirestore.instance
                .collection('userProfiles')
                .doc(updatedProfile.id)
                .update({
              'username': updatedProfile.username,
              'bio': updatedProfile.bio,
              'avatar': finalAvatarUrl,
            });

            if (mounted) {
              setState(() {
                _userProfile = UserProfile(
                  id: updatedProfile.id,
                  username: updatedProfile.username,
                  bio: updatedProfile.bio,
                  avatar: finalAvatarUrl, 
                );
              });
            }
          } catch (e) {
            debugPrint("画像アップロードエラー: $e");
            messenger.showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
          }
        },
      ),
    );
  }

  void _showCreateModal() {
    if (_userProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B3E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CreateMemoryScreen(
          initialAuthor: _userProfile!.username,
          onCancel: () => Navigator.pop(ctx),
          onSubmit: (photoPath, text, author, starRating) async {
            final navigator = Navigator.of(ctx);
            final messenger = ScaffoldMessenger.of(ctx);

            await _api.createMemory(
              localPhotoPath: photoPath,
              text: text,
              authorName: _userProfile!.username,
              authorId: _userProfile!.id,
              starRating: starRating,
            );
            
            if (navigator.canPop()) {
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text('記憶を凍土に封印しました...')));
            }
          },
        ),
      ),
    );
  }

  void _showMemoryDetail(Memory memory) {
    IceEffects.showIceDialog(
      context: context, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IceEffects.memoryDetailContent(memory),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text("${memory.stampsCount} つの輝き", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Icon(Icons.message_outlined, color: Colors.cyan, size: 16),
              SizedBox(width: 8),
              Text("寄せられた言葉", style: TextStyle(color: Colors.cyan, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (memory.guestComments.isEmpty)
             const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("まだ言葉は寄せられていません", style: TextStyle(color: Colors.white38, fontSize: 12)),
            )
          else
             ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: memory.guestComments.length,
                itemBuilder: (context, index) {
                   return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan.withOpacity(0.1)),
                    ),
                    child: Text(
                      "✨ ${memory.guestComments[index]}",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _sanitizeUrl(String url) {
    if (url.contains('dicebear.com') && url.contains('svg')) {
      return url.replaceAll('svg', 'png');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // ログアウト処理中の null 安全ガード
    if (_userProfile == null && !_isLoading) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      // 背景は Stack で描画するため、Scaffold 自体は透明に
      backgroundColor: Colors.transparent, 
      extendBody: true, // ナビゲーションバーの裏まで背景を広げる
      body: Stack(
        children: [
          // 1. 背景：深い凍土のグラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.5,
                colors: [Color(0xFF1E3A5F), Colors.black],
              ),
            ),
          ),

          // 2. キラキラ粒子エフェクト（AnimatedBuilderで動かす）
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: List.generate(35, (index) => _buildBgSparkle(context, index)),
              );
            },
          ),

          // 3. メインコンテンツ
          SafeArea(
            bottom: false,
            child: _isLoading || _userProfile == null
              ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
              : Column(
                  children: [
                    // AppBar の代わり
                    _buildCustomAppBar(), 
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentView = CurrentView.values[index]);
                        },
                        children: [
                          _buildDiscoveryView(),
                          _buildHomeView(),
                          _buildAchievementsView(),
                        ],
                      ),
                    ),
                    AppNavigationBar(
                      currentView: _currentView,
                      onViewChanged: (view) {
                        setState(() => _currentView = view);
                        _pageController.animateToPage(view.index,
                            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                    ),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: _currentView == CurrentView.home 
        ? FloatingActionButton(
            onPressed: _showCreateModal, 
            backgroundColor: Colors.cyan, 
            child: const Icon(Icons.add, color: Colors.black)
          ) 
        : null,
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Frozen Memory', 
            style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Serif', fontWeight: FontWeight.bold)
          ),
          if (_userProfile != null)
            IconButton(
              onPressed: _openProfile, 
              icon: CircleAvatar(
                radius: 16, 
                backgroundColor: Colors.white24,
                backgroundImage: _userProfile!.avatar.startsWith('http') 
                    ? NetworkImage(_sanitizeUrl(_userProfile!.avatar)) 
                    : null,
                child: _userProfile!.avatar.isEmpty ? const Icon(Icons.person, size: 20) : null,
              )
            ),
        ],
      ),
    );
  }

  // --- 各 View のビルドメソッド（変更なし、安全な activeUid チェックを維持） ---
  Widget _buildHomeView() {
    final activeUid = _userProfile?.id;
    if (activeUid == null) return const SizedBox.shrink();

    return StreamBuilder<List<Memory>>(
      stream: _api.watchAllMemories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }
        
        // ★ 修正：条件を「自分が発掘したもの」に限定する
        // 他人が投稿したか自分かは問わず、とにかく「自分が発掘（discoveredBy）」した記憶のみを表示
        final myCollection = (snapshot.data ?? []).where((m) {
          return m.discoveredBy == activeUid; 
        }).toList();

        myCollection.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (myCollection.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: Colors.cyan.withOpacity(0.2)),
                const SizedBox(height: 16),
                const Text("コレクションは空です", style: TextStyle(color: Colors.white38)),
                const Text("「発掘」で誰かの思い出を掘り起こしましょう", 
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            )
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
          ),
          itemCount: myCollection.length,
          itemBuilder: (context, index) {
            final memory = myCollection[index];
            return AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: IceEffects.glassStyle.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.05 + (_shimmerController.value * 0.1)),
                        blurRadius: 8 + (_shimmerController.value * 8),
                      )
                    ],
                  ),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () => _showMemoryDetail(memory),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Stack(
                          children: [
                            Image(
                              image: _getImage(memory.photo), 
                              fit: BoxFit.cover, 
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (c, o, s) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                            ),
                            if (memory.authorId != activeUid)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                  child: const Icon(Icons.verified_user_outlined, color: Colors.cyanAccent, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(memory.author, style: const TextStyle(color: Colors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(memory.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text("✨", style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text("${memory.stampsCount}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
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
      },
    );
  }

  Widget _buildDiscoveryView() {
    final activeUid = _userProfile?.id;
    if (activeUid == null) return const SizedBox.shrink();

    return StreamBuilder<List<Memory>>(
      stream: _api.watchAllMemories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }

        // フィルタリング条件
        final undiscoveredMemories = (snapshot.data ?? []).where((m) {
          return m.authorId != activeUid && 
                 m.discovered == false && 
                 m.discoveredBy != activeUid;
        }).toList();
        
        if (undiscoveredMemories.isEmpty) {
          return const Center(
            child: Text("凍土に埋もれた記憶はすべて掘り起こされました", 
              style: TextStyle(color: Colors.white38, fontSize: 12))
          );
        }

        return DiggingGameScreen(
          allOtherMemories: undiscoveredMemories,
          // ★ 引数を3つ (memory, comment, sendStamp) に更新
          onDiscover: (memory, comment, sendStamp) async {
            final discovererUid = activeUid;

            try {
              // 1. 裏側でFirestoreを更新する
              await _api.unlockMemory(
                memoryId: memory.id,
                userId: discovererUid,
                comment: comment,
                // ★ ユーザーがダイアログで選んだ boolean をそのまま渡す
                sendStampAutomatically: sendStamp,
              );

              // 完了ログ(SnackBar)は削除済み。
              // 演出は DiggingGameScreen 側の _showCelebration() が担当します。
              
            } catch (e) {
              debugPrint("発掘エラー: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('通信に失敗しました。もう一度お試しください。')),
                );
              }
            }
          },
        );
      }
    );
  }

  Widget _buildAchievementsView() {
    return AchievementsScreen();
  }



  ImageProvider _getImage(String path) {
    if (path.isEmpty) return const AssetImage('assets/images/avatar_placeholder.png'); 
    if (kIsWeb || path.startsWith('http') || path.startsWith('https') || path.startsWith('blob:')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  // --- キラキラの粒子ひとつひとつを描画するメソッド ---
  Widget _buildBgSparkle(BuildContext context, int index) {
    final random = Random(index);
    // 粒子の大きさをランダムに設定 (2px 〜 4px)
    final size = random.nextDouble() * 2 + 10; 
    // 画面上の初期位置をランダムに設定
    final baseTop = random.nextDouble() * MediaQuery.of(context).size.height;
    final baseLeft = random.nextDouble() * MediaQuery.of(context).size.width;
    
    // 時間経過とともに上下左右に揺らす計算
    // _bgController.value は 0.0 〜 1.0 の間で変化します
    final drift = sin(_bgController.value * pi * 2 + index) * 15;

    return Positioned(
      top: baseTop + drift,
      left: baseLeft + (drift * 0.5),
      child: Opacity(
        // sin関数を使って、ふわふわと明滅させる
        opacity: (sin(_bgController.value * pi * 2 + index) + 1) / 2 * 0.4,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // 3つに1つは水色、それ以外は白にする
            color: index % 3 == 0 ? Colors.cyanAccent : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

