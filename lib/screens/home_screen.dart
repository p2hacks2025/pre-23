// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
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
  CurrentView _currentView = CurrentView.home;
  bool _createFromHome = false;
  
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  List<Memory> generateDebugMemories() {
    final now = DateTime.now();
    return [
      Memory(
        id: 'debug_1',
        photo: 'https://picsum.photos/id/10/400/400',
        text: '新鮮な思い出（10回クリック）',
        author: 'Tester',
        createdAt: now.subtract(const Duration(days: 2)), // 必須
        discovered: false,                               // 必須
        comments: [],                                    // 必須
      ),
      Memory(
        id: 'debug_2',
        photo: 'https://picsum.photos/id/20/400/400',
        text: 'カチカチの思い出（20回クリック）',
        author: 'Tester',
        createdAt: now.subtract(const Duration(days: 30)), // 必須
        discovered: false,                                // 必須
        comments: [],                                     // 必須
      ),
      Memory(
        id: 'debug_3',
        photo: 'https://picsum.photos/id/30/400/400',
        text: '歴史的な思い出（5回クリック）',
        author: 'Tester',
        createdAt: now.subtract(const Duration(days: 200)), // 必須
        discovered: false,                                 // 必須
        comments: [],                                      // 必須
      ),
    ];
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadData() async {
    try {
      final profile = await _authService.getCurrentUser();
      
      // ネットワークエラーが出る可能性が高い部分を try-catch で囲むか、
      // 一時的にコメントアウトしてデバッグデータのみにします
      /* final userMemories = await _apiService.fetchUserMemories(profile.id);
      final items = await _apiService.fetchUserItems(profile.id);
      ...
      */

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
        _isLoading = false;
        // ❌ エラーが出る通信データの代わりに、生成したデバッグデータを入れる
        _undiscoveredMemories = generateDebugMemories(); 
        _memories = []; // 必要ならここにもサンプルを入れる
      });
    } catch (e) {
      debugPrint('⚠️ Firebase connection failed, using debug data: $e');
      if (mounted) {
        setState(() {
          _undiscoveredMemories = generateDebugMemories();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateMemory(String localPath, String text, String author) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') return;
    await _apiService.postMemory(
      localPhotoPath: localPath, 
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

  Future<void> _handleDiscoverMemory(Memory memory) async {
  setState(() {
    // 1. 対象を「発見済み」に変更
    final found = memory.copyWith(discovered: true);
    
    // 2. 未発見リストから削除
    _undiscoveredMemories.removeWhere((m) => m.id == memory.id);
    
    // 3. 発見済みリストの先頭に追加
    _memories.insert(0, found);
    
    // 4. 即座にホーム画面に戻る
    _currentView = CurrentView.home;
  });

  // 裏でFirebase保存（エラーが起きても画面は更新済み）
  try {
    await _apiService.discoverMemory(memory, _userProfile.id);
  } catch (e) {
    print("Firebase update failed: $e");
  }
}

  Future<void> _handleDiscoverItem(Item item) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') return;
    await _apiService.discoverItem(item, user.id);
    await _loadData();
  }

  void _setDailyDigs(int newCount) {
    if (mounted) setState(() => _dailyDigs = newCount);
  }

  Future<void> _handleSaveProfile(UserProfile updatedProfile) async {
    await _authService.signInWithUsername(updatedProfile.username); 
    await _loadData();
  }

  void _handleRequestSignIn() {
    showDialog(
      context: context,
      builder: (context) => SignInScreen(
        onSignedIn: (profile) async {
          Navigator.of(context).pop();
          await _loadData();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    switch (_currentView) {
      case CurrentView.home:
        final allMemories = [..._memories, ..._undiscoveredMemories];
  return MemoryPostScreen(
        memories: allMemories,
        // ★ エラー解決: 必須パラメータをすべて追加
        onAddComment: (memoryId, text, author) async {
          final user = await _authService.getCurrentUser();
          final newComment = Comment(
            id: _apiService.uuidGenerator.v4(),
            author: author,
            text: text,
            createdAt: DateTime.now(),
          );
          await _apiService.addComment(memoryId, newComment);
          _loadData();
        },
        onEditMemory: (memory) {
          // 編集処理が必要ならここに記述
        },
        onDeleteMemory: (id) async {
          await _apiService.deleteMemory(id);
          _loadData();
        },
        // ★ 追加: 凍った投稿をタップした時に発掘画面へ
        onTapMemory: (memory) {
          if (!memory.discovered) {
            setState(() {
              _currentView = CurrentView.dig;
              // ターゲットを指定したい場合は変数を追加して保持する
            });
          }
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
          // ここには他の引数を入れないでください
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
                builder: (context) => ProfileScreen(
                  profile: _userProfile,
                  onSave: _handleSaveProfile,
                  onClose: () => Navigator.of(context).pop(),
                  onRequestSignIn: _handleRequestSignIn,
                ),
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
              AppNavigationBar(
                currentView: _currentView,
                onViewChanged: (view) => setState(() => _currentView = view),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentView = CurrentView.create;
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