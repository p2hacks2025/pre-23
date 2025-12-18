import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/memory.dart';
import '../models/user_profile.dart';
import '../services/demo_data.dart';
import 'digging_game_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/effects.dart';
//lib/screens/home_screen.dart

enum CurrentView { discovery, home, achievements }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  CurrentView _currentView = CurrentView.home;
  bool _isLoading = true;
  late PageController _pageController;
  
  // ★ キラキラ光るアニメーション用のコントローラー
  late AnimationController _shimmerController;
  
  UserProfile _userProfile = UserProfile(
    id: 'user_123', 
    username: '探索者', 
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix', 
    bio: '凍土に眠る記憶を探しています'
  );
  
  List<Memory> _memories = [];
  final _picker = ImagePicker();
  final _createController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    
    // ★ グロー効果（呼吸するように光る）のアニメーション設定
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _memories = DemoData.getMemories();
      _isLoading = false;
    });
  }

  // --- 投稿・プロフィール・詳細表示 ---
  
  void _showMemoryDetail(Memory memory) {
    // 詳細を開いたときにキラキラが少し強調される演出
    IceEffects.showIceDialog(
      context: context, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IceEffects.memoryDetailContent(memory),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
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
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
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
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- メインビルド ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Flozend Memory', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _openProfile, icon: CircleAvatar(radius: 16, backgroundImage: NetworkImage(_userProfile.avatar))),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
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
        ? FloatingActionButton(onPressed: _showCreateModal, backgroundColor: Colors.cyan, child: const Icon(Icons.add)) 
        : null,
    );
  }

  Widget _buildHomeView() {
    final discoveredMems = _memories.where((m) => m.authorId != _userProfile.id && m.discovered).toList();
    if (discoveredMems.isEmpty) return const Center(child: Text("発掘済みの思い出がありません", style: TextStyle(color: Colors.white38)));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
      ),
      itemCount: discoveredMems.length,
      itemBuilder: (context, index) {
        final memory = discoveredMems[index];
        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              decoration: IceEffects.glassStyle.copyWith(
                // ★ カードの周りが呼吸するように光るエフェクト
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.1 + (_shimmerController.value * 0.15)),
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
                    child: Image(image: _getImage(memory.photo), fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memory.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (memory.guestComments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("💬 ${memory.guestComments.last}", style: const TextStyle(color: Colors.cyan, fontSize: 11), maxLines: 1),
                        ),
                      const SizedBox(height: 8),
                      // キラキラ数表示
                      Row(
                        children: [
                          const Text("✨", style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text("${memory.stampsCount}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
  }

  // --- 他のビューとユーティリティ (変更なし) ---
  
  Widget _buildDiscoveryView() => DiggingGameScreen(
    allOtherMemories: _memories.where((m) => m.authorId != _userProfile.id).toList(),
    onDiscover: (m) => setState(() => m.discovered = true),
  );

  Widget _buildAchievementsView() => const AchievementsScreen();

  void _openProfile() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => ProfileScreen(
        profile: _userProfile,
        onSave: (newProfile) => setState(() => _userProfile = newProfile),
        onClose: () => Navigator.pop(context),
        onRequestSignIn: () {},
      ),
    );
  }

  void _showCreateModal() {
    XFile? tempImage;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(color: Color(0xFF0D1B3E), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('記憶を凍結する', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final img = await _picker.pickImage(source: ImageSource.gallery);
                  if (img != null) setModalState(() => tempImage = img);
                },
                child: Container(
                  height: 200, width: double.infinity,
                  decoration: IceEffects.glassStyle.copyWith(
                    image: tempImage != null ? DecorationImage(image: kIsWeb ? NetworkImage(tempImage!.path) : FileImage(File(tempImage!.path)) as ImageProvider, fit: BoxFit.cover) : null,
                  ),
                  child: tempImage == null ? const Icon(Icons.add_a_photo, color: Colors.cyan, size: 40) : null,
                ),
              ),
              TextField(controller: _createController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: '何を封印しますか？', hintStyle: TextStyle(color: Colors.white24))),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (tempImage != null && _createController.text.isNotEmpty) {
                    setState(() {
                      _memories.insert(0, Memory(
                        id: DateTime.now().toString(), photo: tempImage!.path, text: _createController.text, author: _userProfile.username, authorId: _userProfile.id, createdAt: DateTime.now(), discovered: false, comments: [], guestComments: [], stampsCount: 0, digCount: 0, starRating: 3,
                      ));
                    });
                    _createController.clear();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: const Size(double.infinity, 50)),
                child: const Text('凍土に封印する', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getImage(String path) {
    if (path.startsWith('http') || kIsWeb) return NetworkImage(path);
    return FileImage(File(path));
  }
}