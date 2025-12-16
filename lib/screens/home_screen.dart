// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/memory.dart';
import '../models/comment.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'memory_post_screen.dart';
import 'create_memory_screen.dart';
import 'digging_game_screen.dart';
// import 'collection_screen.dart'; // ★ 削除
import 'achievements_screen.dart';
import 'profile_screen.dart';
import '../widgets/navigation_bar.dart';
import 'sign_in_screen.dart';
import '../models/user_profile.dart';

// CurrentViewから collection を削除
enum CurrentView {
  home,
  create,
  dig,
  achievements,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _createMemoryKey = GlobalKey();
  
  late PageController _pageController;

  CurrentView _currentView = CurrentView.home;
  bool _createFromHome = false;
  
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // データ
  UserProfile _userProfile = UserProfile(id: '', username: '', avatar: '', bio: '');
  List<Memory> _memories = [];
  // アイテムデータは発掘ゲームのロジック維持のため残していますが、表示はしません
 
  List<Achievement> _achievements = [];
  List<Memory> _undiscoveredMemories = [];
  int _totalDigs = 0;
  int _dailyDigs = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ★ インデックスの対応を変更（コレクション削除により）
  int _viewToIndex(CurrentView view) {
    switch (view) {
      case CurrentView.home: return 0;
      case CurrentView.dig: return 1;
      case CurrentView.achievements: return 2; // 3 -> 2へ
      default: return 0;
    }
  }

  CurrentView _indexToView(int index) {
    switch (index) {
      case 0: return CurrentView.home;
      case 1: return CurrentView.dig;
      case 2: return CurrentView.achievements; // 3 -> 2へ
      default: return CurrentView.home;
    }
  }

  void _navigateToView(CurrentView view) {
    setState(() {
      _currentView = view;
    });

    if (view != CurrentView.create) {
      _pageController.jumpToPage(_viewToIndex(view));
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final profile = await _authService.getCurrentUser();
      final userMemories = await _apiService.fetchUserMemories(profile.id);
      //final items = await _apiService.fetchUserItems(profile.id);
      final achievementData = await _apiService.fetchUserAchievementsAndDigs(profile.id);
      final achievements = achievementData['achievements'] as List<Achievement>;
      final totalDigs = achievementData['totalDigs'] as int;
      final undiscoveredMemories = await _apiService.fetchUndiscoveredMemories(profile.id);
      final lastDigDate = await _apiService.fetchLastDigDate(profile.id);

      int dailyDigs = _dailyDigs;
      if (lastDigDate == null || !isSameDay(lastDigDate, now)) {
        dailyDigs = 3;
      }

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
        _memories = userMemories;

        _achievements = achievements;
        _totalDigs = totalDigs;
        _undiscoveredMemories = undiscoveredMemories;
        _dailyDigs = dailyDigs;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('❌ _loadData error: $e');
      debugPrintStack(stackTrace: s);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateMemory(
      String localPhotoPath, String text, String author) async {
    final user = await _authService.getCurrentUser();
    
    if (user.id == 'guest') {
      if (kDebugMode) print('ゲストユーザーは投稿できません。');
      return; 
    }
    
    await _apiService.postMemory(
      localPhotoPath: localPhotoPath, 
      text: text,
      author: author,
      authorId: user.id, 
    );

    await _loadData();

    // 投稿後はホームに戻る
    _navigateToView(CurrentView.home);
    setState(() {
      _createFromHome = false;
    });
  }

  Future<void> _handleDiscoverMemory(Memory memory) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') return;

    await _apiService.discoverMemory(memory, user.id); 
    await _loadData();
  }

  Future<void> _handleDiscoverItem(Item item) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') return;

    await _apiService.discoverItem(item, user.id);
    await _loadData();
  }

  void _setDailyDigs(int newCount) {
    if (mounted) {
      setState(() {
        _dailyDigs = newCount;
      });
    }
  }

  Future<void> _handleSaveProfile(UserProfile updatedProfile) async {
    await _authService.signInWithUsername(updatedProfile.username); 
    await _loadData();
  }

  void _handleRequestSignIn() {
    showDialog(
      context: context,
      builder: (context) {
        return SignInScreen(
          onSignedIn: (profile) async {
            Navigator.of(context).pop();
            await _loadData();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyan),
            SizedBox(height: 12),
            Text('Loading...', style: TextStyle(color: Colors.cyan)),
          ],
        ),
      );
    }

    if (_currentView == CurrentView.create) {
      return CreateMemoryScreen(
        key: _createMemoryKey,
        initialAuthor: _createFromHome ? _userProfile.username : null,
        onSubmit: _handleCreateMemory,
        onCancel: () {
          _navigateToView(CurrentView.home);
          setState(() {
            _createFromHome = false;
          });
        },
      );
    }

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentView = _indexToView(index);
        });
      },
      // ★ CollectionScreenを削除し、3画面構成に変更
      children: [
        // 0: Home
        MemoryPostScreen(
          memories: _memories,
          onAddComment: (memoryId, text, author) async {
            final user = await _authService.getCurrentUser();
            if (user.id == 'guest') return;
            
            final newComment = Comment(
              id: _apiService.uuidGenerator.v4(),
              author: author,
              text: text,
              createdAt: DateTime.now(),
            );
            await _apiService.addComment(memoryId, newComment);
            await _loadData();
          },
          onEditMemory: (memory) async {},
          onDeleteMemory: (id) async {},
        ),
        
        // 1: Dig (Game)
        DiggingGameScreen(
          undiscoveredMemories: _undiscoveredMemories,
          onDiscover: _handleDiscoverMemory,
          onDiscoverItem: _handleDiscoverItem, // ロジック上は残しておく
          dailyDigs: _dailyDigs,
          onDailyDigsChanged: _setDailyDigs,
        ),
        
        // 2: Achievements (ここが3番目に)
        AchievementsScreen(
          achievements: _achievements,
          totalDigs: _totalDigs, 
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _currentView == CurrentView.home && _userProfile.id != 'guest';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('永久凍土の記憶', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyan.withValues(alpha: 0.2), 
              child: Text(_userProfile.username.isNotEmpty ? _userProfile.username[0] : 'G',
                  style: const TextStyle(color: Colors.cyan)),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return ProfileScreen(
                    profile: _userProfile,
                    onSave: _handleSaveProfile,
                    onClose: () => Navigator.of(context).pop(),
                    onRequestSignIn: _handleRequestSignIn,
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(child: _buildBody()),
              // 下のナビゲーションバー
              AppNavigationBar(
                currentView: _currentView,
                onViewChanged: _navigateToView,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      floatingActionButton: showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton(
                onPressed: () {
                  _navigateToView(CurrentView.create);
                  setState(() {
                    _createFromHome = true;
                  });
                },
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
                child: const Icon(Icons.edit),
              ),
            )
          : null,
    );
  }
}