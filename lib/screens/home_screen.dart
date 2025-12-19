// lib/screens/home_screen.dart

import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initUser();
  }

  Future<void> _initUser() async {
    try {
      final profile = await _auth.getCurrentUser();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ユーザー読み込みエラー: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

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
          // ★修正ポイント: 非同期処理の前にMessengerを確保する
          final messenger = ScaffoldMessenger.of(context);

          try {
            String finalAvatarUrl = updatedProfile.avatar;

            // 画像アップロード処理
            if (finalAvatarUrl.isNotEmpty && !finalAvatarUrl.startsWith('http')) {
              final file = File(finalAvatarUrl);
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('user_avatars')
                  .child('${updatedProfile.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

              await storageRef.putFile(file);
              finalAvatarUrl = await storageRef.getDownloadURL();
            }

            // 1. Firestore更新
            await FirebaseFirestore.instance
                .collection('userProfiles')
                .doc(updatedProfile.id)
                .update({
              'username': updatedProfile.username,
              'bio': updatedProfile.bio,
              'avatar': finalAvatarUrl,
            });

            // 2. ホーム画面側の状態も更新
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
            debugPrint("プロフィール更新エラー: $e");
            // ★確保したmessengerを使って表示
            messenger.showSnackBar(
              SnackBar(content: Text('更新に失敗しました: $e')),
            );
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
            // ★修正: NavigatorとMessengerを事前に確保
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
              messenger.showSnackBar(
                const SnackBar(content: Text('記憶を凍土に封印しました...')),
              );
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyan.withValues(alpha: 0.1)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Frozen Memory', style: TextStyle(color: Colors.white, fontFamily: 'Serif', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
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
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading || _userProfile == null
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan)) 
        : Column(
            children: [
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
                  _pageController.animateToPage(view.index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
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

  Widget _buildHomeView() {
    return StreamBuilder<List<Memory>>(
      // 他人の思い出をリアルタイム監視
      stream: _api.watchOthersMemories(_userProfile!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }
        
        // ★ 修正：他人の思い出の中で、すでに「発掘（解凍）済み」のものだけを表示
        final discoveredCollection = (snapshot.data ?? [])
            .where((m) => m.discovered == true)
            .toList();

        if (discoveredCollection.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: Colors.cyan.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                const Text("コレクションは空です", style: TextStyle(color: Colors.white38)),
                const Text("「発掘」で誰かの思い出を救い出しましょう", 
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
          itemCount: discoveredCollection.length,
          itemBuilder: (context, index) {
            final memory = discoveredCollection[index];
            return AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: IceEffects.glassStyle.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.05 + (_shimmerController.value * 0.1)),
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
                        child: Image(
                          image: _getImage(memory.photo), 
                          fit: BoxFit.cover, 
                          width: double.infinity,
                          errorBuilder: (c, o, s) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 他人の思い出なので作成者名を表示
                          Text(memory.author, 
                            style: const TextStyle(color: Colors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(memory.text, maxLines: 1, overflow: TextOverflow.ellipsis, 
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
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
    return StreamBuilder<List<Memory>>(
      stream: _api.watchOthersMemories(_userProfile!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }
        
        // ★ 修正：他人の思い出の中で「まだ誰も発掘していない」ものだけを表示
        final undiscoveredMemories = (snapshot.data ?? [])
            .where((m) => m.discovered == false)
            .toList();
        
        if (undiscoveredMemories.isEmpty) {
           return const Center(
             child: Text("凍土に埋もれた記憶はすべて掘り起こされました", 
               style: TextStyle(color: Colors.white38, fontSize: 12))
           );
        }

        return DiggingGameScreen(
          allOtherMemories: undiscoveredMemories,
          onDiscover: (memory) {
            // ApiService側で discovered = true に更新する
            _api.unlockMemory(memory.id, _userProfile!.id);
            _api.sendStamp(memory.id); 
          },
        );
      }
    );
  }

  Widget _buildAchievementsView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _api.fetchUserAchievementsAndDigs(_userProfile!.id),
      builder: (context, snapshot) {
        return const AchievementsScreen(); 
      },
    );
  }
ImageProvider _getImage(String path) {
    // パスが空なら、例のダミー画像（もしくはassetsの画像）
    if (path.isEmpty) {
      // ネット環境がない場合も考慮するなら、前回作った 'assets/images/...' の方が安全です
      return const AssetImage('assets/images/avatar_placeholder.png'); 
    }

    // ★ Web環境、またはURL形式の場合は NetworkImage
    // (startsWith('blob:') はWebで画像選択した直後の一時パス対応です)
    if (kIsWeb || path.startsWith('http') || path.startsWith('https') || path.startsWith('blob:')) {
      return NetworkImage(path);
    }

    // スマホアプリ（Android/iOS）のローカルファイル
    return FileImage(File(path));
  }

}