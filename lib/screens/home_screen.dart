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
import 'collection_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import '../widgets/navigation_bar.dart';
import 'sign_in_screen.dart';
import '../models/user_profile.dart';

enum CurrentView {
  home,
  create,
  dig,
  collection,
  achievements,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _createMemoryKey = GlobalKey();
  
  // ★ PageView用のコントローラーを追加
  late PageController _pageController;

  CurrentView _currentView = CurrentView.home;
  bool _createFromHome = false;
  
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // データ
  UserProfile _userProfile = UserProfile(id: '', username: '', avatar: '', bio: '');
  List<Memory> _memories = [];
  List<Item> _items = [];
  List<Achievement> _achievements = [];
  List<Memory> _undiscoveredMemories = [];
  int _totalDigs = 0;
  int _dailyDigs = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ★ コントローラーの初期化
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    // ★ コントローラーの破棄（メモリリーク防止）
    _pageController.dispose();
    super.dispose();
  }

  // ★ 画面（View）とページ番号（Index）を変換するヘルパー
  // Create画面はPageViewに含まないため、除外してマッピングします
  int _viewToIndex(CurrentView view) {
    switch (view) {
      case CurrentView.home: return 0;
      case CurrentView.dig: return 1;
      case CurrentView.collection: return 2;
      case CurrentView.achievements: return 3;
      default: return 0;
    }
  }

  CurrentView _indexToView(int index) {
    switch (index) {
      case 0: return CurrentView.home;
      case 1: return CurrentView.dig;
      case 2: return CurrentView.collection;
      case 3: return CurrentView.achievements;
      default: return CurrentView.home;
    }
  }

  // ★ 画面切り替えの処理を統合
  void _navigateToView(CurrentView view) {
    setState(() {
      _currentView = view;
    });

    // Create以外の画面なら、PageViewも該当ページへスクロールさせる
    if (view != CurrentView.create) {
      // jumpToPageなら一瞬で切り替え、animateToPageならスワイプのように動く
      // Instagram風ならタップ時は一瞬で切り替わることが多いのでjumpToPage推奨
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
      final items = await _apiService.fetchUserItems(profile.id);
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
        _items = items;
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

  // ★ _buildBodyをPageViewを使う形に大幅変更
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

    // 投稿モード（Create）のときは、スワイプできない画面を表示する
    if (_currentView == CurrentView.create) {
      return CreateMemoryScreen(
        key: _createMemoryKey,
        initialAuthor: _createFromHome ? _userProfile.username : null,
        onSubmit: _handleCreateMemory,
        onCancel: () {
          // キャンセル時はホームに戻る
          _navigateToView(CurrentView.home);
          setState(() {
            _createFromHome = false;
          });
        },
      );
    }

    // それ以外のときは、スワイプ可能なPageViewを表示する
    return PageView(
      controller: _pageController,
      // スワイプした時に下のナビゲーションバーも連動させる
      onPageChanged: (index) {
        setState(() {
          _currentView = _indexToView(index);
        });
      },
      // 画面リスト (順番は _viewToIndex と合わせる: Home -> Dig -> Collection -> Achievements)
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
          onDiscoverItem: _handleDiscoverItem,
          dailyDigs: _dailyDigs,
          onDailyDigsChanged: _setDailyDigs,
        ),
        
        // 2: Collection
        CollectionScreen(items: _items),
        
        // 3: Achievements
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
              backgroundColor: Colors.cyan.withAlpha((0.2 * 255).round()), 
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
                // ボタンを押した時の処理を _navigateToView に変更
                onViewChanged: _navigateToView,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                // FABを押した時は Createモードへ（スワイプ不可画面へ）
                _navigateToView(CurrentView.create);
                setState(() {
                  _createFromHome = true;
                });
              },
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}