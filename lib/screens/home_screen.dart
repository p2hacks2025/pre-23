// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/memory.dart';
import '../models/comment.dart';
import '../models/game.dart';
import '../services/api_service.dart'; // データ操作
import '../services/auth_service.dart'; // 認証操作
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
  CurrentView _currentView = CurrentView.home;
  bool _createFromHome = false;
  
  // サービスインスタンス
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // データ
  UserProfile _userProfile = UserProfile(id: '', username: '', avatar: '', bio: '');
  List<Memory> _memories = []; // 自分の投稿
  List<Item> _items = []; // 発掘したアイテム
  List<Achievement> _achievements = []; // 実績
  List<Memory> _undiscoveredMemories = []; // 発掘ゲーム用リスト
  int _totalDigs = 0; // 累積発掘回数
  int _dailyDigs = 3; // デイリー発掘残り回数 (仮の初期値)
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();

    // 1フレーム描画後に Firebase を使う
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }


  // 日付が同じかどうかをチェックするヘルパー関数
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();

      // 1. 認証ユーザー取得
      final profile = await _authService.getCurrentUser();

      // 2. データ取得
      final userMemories =
          await _apiService.fetchUserMemories(profile.id);

      final items =
          await _apiService.fetchUserItems(profile.id);

      final achievementData =
          await _apiService.fetchUserAchievementsAndDigs(profile.id);

      final achievements =
          achievementData['achievements'] as List<Achievement>;
      final totalDigs =
          achievementData['totalDigs'] as int;

      final undiscoveredMemories =
          await _apiService.fetchUndiscoveredMemories(profile.id);

      final lastDigDate =
          await _apiService.fetchLastDigDate(profile.id);

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
      // ★ ここ超重要（exe で原因が見える）
      debugPrint('❌ _loadData error: $e');
      debugPrintStack(stackTrace: s);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 記憶投稿のハンドラ
  Future<void> _handleCreateMemory(
      String localPhotoPath, String text, String author) async {
    final user = await _authService.getCurrentUser();
    
    if (user.id == 'guest') {
      if (kDebugMode) {
        print('ゲストユーザーは投稿できません。');
      }
      return; 
    }
    
    await _apiService.postMemory(
      localPhotoPath: localPhotoPath, 
      text: text,
      author: author,
      authorId: user.id, 
    );

    await _loadData();

    setState(() {
      _currentView = CurrentView.home;
      _createFromHome = false;
    });
  }

  // 記憶発掘のハンドラ
  Future<void> _handleDiscoverMemory(Memory memory) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') return;

    await _apiService.discoverMemory(memory, user.id); 
    
    await _loadData();
  }

  // アイテム発掘のハンドラ
  Future<void> _handleDiscoverItem(Item item) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') return;

    await _apiService.discoverItem(item, user.id);

    await _loadData();
  }

  // デイリー発掘回数の設定
  void _setDailyDigs(int newCount) {
    if (mounted) {
      setState(() {
        _dailyDigs = newCount;
      });
    }
  }

  // プロフィール編集の保存ハンドラ
  Future<void> _handleSaveProfile(UserProfile updatedProfile) async {
    await _authService.signInWithUsername(updatedProfile.username); 
    await _loadData();
  }

  // 認証フロー
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

    switch (_currentView) {
      case CurrentView.home:
        return MemoryPostScreen(
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
          onEditMemory: (memory) async {
            // ... (実装が必要)
          },
          onDeleteMemory: (id) async {
            // ... (実装が必要)
          },
        );
      case CurrentView.create:
        return CreateMemoryScreen(
          key: _createMemoryKey,
          initialAuthor: _createFromHome ? _userProfile.username : null,
          onSubmit: _handleCreateMemory,
          onCancel: () => setState(() {
            _currentView = CurrentView.home;
            _createFromHome = false;
          }),
        );
      case CurrentView.dig:
        return DiggingGameScreen(
          undiscoveredMemories: _undiscoveredMemories,
          onDiscover: _handleDiscoverMemory,
          onDiscoverItem: _handleDiscoverItem,
          dailyDigs: _dailyDigs,
          onDailyDigsChanged: _setDailyDigs,
        );
      case CurrentView.collection:
        return CollectionScreen(items: _items); 
      case CurrentView.achievements:
        return AchievementsScreen(
          achievements: _achievements,
          totalDigs: _totalDigs, 
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // FABを表示するかどうかの判定
    // ホーム画面 かつ ゲストでない場合に表示
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
              // withValues()の推奨警告への対応としてwithAlphaを使用
              backgroundColor: Colors.cyan.withAlpha((0.2 * 255).round()), 
              child: Text(_userProfile.username.isNotEmpty ? _userProfile.username[0] : 'G',
                  style: const TextStyle(color: Colors.cyan)),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // ★ これを追加！（重要）
                backgroundColor: Colors.transparent, // 背景を透過させる（角丸のため）
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
              // AppNavigationBarでは、'create'ボタンを非表示にする等の修正が必要かもしれません
              AppNavigationBar(
                currentView: _currentView,
                onViewChanged: (view) => setState(() => _currentView = view),
                // hideCreateButton の行を削除
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // ★ ここに追加しました
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  // FABを押すと投稿画面（CreateMemoryScreen）へ遷移
                  _currentView = CurrentView.create;
                  _createFromHome = true;
                });
              },
              backgroundColor: Colors.cyan, // 世界観に合わせた色
              foregroundColor: Colors.black, // アイコンの色
              child: const Icon(Icons.edit), // 投稿・編集アイコン
            )
          : null,
    );
  }
}