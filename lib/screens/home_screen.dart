// lib/screens/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb用
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
        onSave: (updated) {
          setState(() => _userProfile = updated);
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
            // ★ 修正: 非同期処理の前にNavigatorやMessengerを確保しておく（安全策）
            final navigator = Navigator.of(ctx);
            final messenger = ScaffoldMessenger.of(ctx);

            await _api.createMemory(
              localPhotoPath: photoPath,
              text: text,
              authorName: _userProfile!.username,
              authorId: _userProfile!.id,
              starRating: starRating,
            );
            
            // 画面がまだ存在しているかチェックしてから閉じる
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
                        // ★ 修正: withOpacity -> withValues
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
                    ? NetworkImage(_userProfile!.avatar) 
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
      stream: _api.watchMyMemories(_userProfile!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }
        
        final myMemories = snapshot.data ?? [];

        if (myMemories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ★ 修正: withOpacity -> withValues
                Icon(Icons.ac_unit, size: 64, color: Colors.cyan.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text("まだ記憶を封印していません", style: TextStyle(color: Colors.white38)),
              ],
            )
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
          ),
          itemCount: myMemories.length,
          itemBuilder: (context, index) {
            final memory = myMemories[index];
            return AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: IceEffects.glassStyle.copyWith(
                    boxShadow: [
                      BoxShadow(
                        // ★ 修正: withOpacity -> withValues
                        color: Colors.cyan.withValues(alpha: 0.1 + (_shimmerController.value * 0.15)),
                        blurRadius: 10 + (_shimmerController.value * 10),
                        spreadRadius: 1,
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
                          Text(memory.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text("✨", style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text("${memory.stampsCount}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
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
        final otherMemories = snapshot.data ?? [];
        
        if (otherMemories.isEmpty) {
           return const Center(child: Text("発掘できる記憶がまだありません", style: TextStyle(color: Colors.white38)));
        }

        return DiggingGameScreen(
          allOtherMemories: otherMemories,
          onDiscover: (memory) {
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
    if (path.isEmpty) return const NetworkImage('https://via.placeholder.com/150');
    if (path.startsWith('http') || kIsWeb) return NetworkImage(path);
    return FileImage(File(path));
  }
}