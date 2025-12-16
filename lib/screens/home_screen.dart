import 'package:flutter/material.dart';

// Models
import '../models/memory.dart';
import '../models/comment.dart';
import '../models/game.dart';
import '../models/user_profile.dart';

// Services
import '../services/api_service.dart';
import '../services/auth_service.dart';

// Screens
import 'memory_post_screen.dart';
import 'create_memory_screen.dart';
import 'digging_game_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import 'sign_in_screen.dart';

// Widgets
import '../widgets/navigation_bar.dart';

// コレクションを削除したEnum定義
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
  
  // PageViewコントローラー
  late PageController _pageController;

  CurrentView _currentView = CurrentView.home;
  bool _createFromHome = false;
  
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // データ状態
  UserProfile _userProfile = UserProfile(id: 'guest', username: 'Guest', avatar: '', bio: '');
  List<Memory> _memories = [];
  // List<Item> _items = []; // ★削除: 使われていないフィールド
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

  // 画面インデックス管理
  int _viewToIndex(CurrentView view) {
    switch (view) {
      case CurrentView.home: return 0;
      case CurrentView.dig: return 1;
      case CurrentView.achievements: return 2;
      default: return 0;
    }
  }

  CurrentView _indexToView(int index) {
    switch (index) {
      case 0: return CurrentView.home;
      case 1: return CurrentView.dig;
      case 2: return CurrentView.achievements;
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
      if (!mounted) return;
      setState(() => _isLoading = true);

      final now = DateTime.now();
      
      final profile = await _authService.getCurrentUser();
      
      final userMemories = await _apiService.fetchUserMemories(profile.id);
      
      final achievementData = await _apiService.fetchUserAchievementsAndDigs(profile.id);
      
      // ★★★ ここを修正しました ★★★
      // 'as List<Achievement>' だとエラーになるため、明示的にキャストします
      final rawAchievements = achievementData['achievements'] as List;
      final achievements = rawAchievements.cast<Achievement>().toList();
      
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
  // ★ 新規投稿
  Future<void> _handleCreateMemory(
      String localPhotoPath, String text, String author) async {
    final user = await _authService.getCurrentUser();
    
    // ★追加: async後のBuildContext使用前にガード
    if (!mounted) return;
    
    if (user.id == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿するにはログインが必要です')),
      );
      return; 
    }
    
    await _apiService.postMemory(
      localPhotoPath: localPhotoPath, 
      text: text,
      author: author,
      authorId: user.id, 
    );

    await _loadData();

    _navigateToView(CurrentView.home);
    setState(() {
      _createFromHome = false;
    });
  }

  // 記憶の発見
  Future<void> _handleDiscoverMemory(Memory memory) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') {
        return; 
    }

    await _apiService.discoverMemory(memory, user.id); 
    await _loadData();
  }

  // アイテム発見
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

  // プロフィール更新
  Future<void> _handleSaveProfile(UserProfile updatedProfile) async {
    await _loadData();
  }
// ★ サインイン処理（上部通知・自動消滅版）
  void _handleRequestSignIn() {
    showDialog(
      context: context, // Homeのcontext
      barrierDismissible: false,
      builder: (dialogContext) {
        return SignInScreen(
          onSignedIn: (profile) async {
            // 1. ログイン画面（ダイアログ）を閉じる
            Navigator.of(dialogContext).pop(); 
            
            // 2. プロフィール画面（ボトムシート）を閉じる
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            
            // 3. データを更新
            await _loadData();
            
            // 4. 画面上部に通知を出す
            if (!mounted) return;

            // 画面の高さを取得して、下からの余白を計算することで上部に配置する
            final double screenHeight = MediaQuery.of(context).size.height;
            
            // 既存の通知があれば消してから出す
            ScaffoldMessenger.of(context).removeCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'ログイン成功！ おかえりなさい ${profile.username}さん',
                  textAlign: TextAlign.center, // テキストを中央寄せ
                  style: const TextStyle(
                    color: Colors.black, // 背景がCyanなので黒文字が見やすい
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.cyan,
                behavior: SnackBarBehavior.floating, // 浮遊タイプにする
                
                // ★ここがポイント: 画面下からの距離を「画面の高さ - 150」くらいにして上部に持ってくる
                margin: EdgeInsets.only(
                  bottom: screenHeight - 150, 
                  left: 20,
                  right: 20,
                ),
                
                // ★ 3秒で自動的に消える（ボタン操作不要）
                duration: const Duration(seconds: 3), 
                
                // action（ボタン）を設定しないので、ボタンは表示されません
              ),
            );
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
  // ★ ログアウト処理
  Future<void> _handleSignOut() async {
    await _authService.signOut();
    await _loadData();
    
    if (mounted) {
       Navigator.of(context).pop(); // プロフィール画面を閉じる
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログアウトしました')),
      );
    }
  }

  // コメント追加処理
  Future<void> _handleAddComment(String memoryId, String text, String author) async {
    final user = await _authService.getCurrentUser();
    if (user.id == 'guest') {
      _showLoginRequiredDialog();
      return;
    }
    
    final newComment = Comment(
      id: _apiService.uuidGenerator.v4(),
      author: author,
      text: text,
      createdAt: DateTime.now(),
    );
    await _apiService.addComment(memoryId, newComment);
    await _loadData();
  }

  // ログイン誘導ダイアログ
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログインが必要です'),
        content: const Text('いいねやコメントをするにはログインしてください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleRequestSignIn();
            },
            child: const Text('ログイン画面へ'),
          ),
        ],
      ),
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
      children: [
        // 0: Home (自分のタイムライン)
        MemoryPostScreen(
          memories: _memories,
          onAddComment: _handleAddComment,
          onEditMemory: (memory) async {},
          onDeleteMemory: (id) async {},
        ),
        
        // 1: Dig (発掘ゲーム - 他人の投稿閲覧)
        DiggingGameScreen(
          undiscoveredMemories: _undiscoveredMemories,
          onDiscover: _handleDiscoverMemory,
          onDiscoverItem: _handleDiscoverItem,
          dailyDigs: _dailyDigs,
          onDailyDigsChanged: _setDailyDigs,
        ),
        
        // 2: Achievements
        AchievementsScreen(
          achievements: _achievements,
          totalDigs: _totalDigs, 
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _currentView == CurrentView.home && !_authService.isGuest;

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
              child: Text(
                _userProfile.username.isNotEmpty ? _userProfile.username[0] : 'G',
                style: const TextStyle(color: Colors.cyan)
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return ProfileScreen(
                    profile: _userProfile,
                    isGuest: _authService.isGuest,
                    onRequestSignIn: _handleRequestSignIn,
                    onSignOut: _handleSignOut,
                    onSave: _handleSaveProfile,
                    onClose: () => Navigator.of(context).pop(),
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