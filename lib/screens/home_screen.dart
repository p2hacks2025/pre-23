import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'memory_post_screen.dart';
import 'create_memory_screen.dart';
import 'digging_game_screen.dart';
import 'profile_screen.dart';
import '../widgets/navigation_bar.dart';
import 'sign_in_screen.dart';
import '../models/user_profile.dart';

// Viewの定義
enum CurrentView { home, mypage, create, dig }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CurrentView _currentView = CurrentView.home;
  Memory? _selectedDigTarget;
  bool _isLoading = true;
  int _dailyDigs = 3;

  UserProfile _userProfile = UserProfile(id: 'guest', username: 'ゲスト', avatar: '', bio: '');
  List<Memory> _memories = [];

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _memories = generateDebugMemories(profile);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- サインイン処理 ---
  void _handleRequestSignIn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignInScreen(
        onSignedIn: (profile) async {
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          
          await _loadData();
          setState(() {
            _currentView = CurrentView.home;
          });
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  // --- 記憶の投稿処理 (匿名投稿を許可) ---
  Future<void> _handleCreateMemory(String path, String text, String author, int stars) async {
    // ★ 修正: _userProfile.id == 'guest' のガードを外し、匿名でも投稿可能にする
    // ただし、authorが空の場合は「名無しさん」などにする
    final String finalAuthor = author.isEmpty ? '凍土の旅人' : author;

    try {
      await _apiService.postMemory(
        localPhotoPath: path,
        text: text,
        author: finalAuthor,
        authorId: _userProfile.id, // 'guest' のまま送信
      );
      
      // 投稿後にデータを更新
      await _loadData();
      
      // 投稿一覧へ遷移（匿名でもマイページで見れるようにする）
      if (mounted) setState(() => _currentView = CurrentView.mypage);
      
    } catch (e) {
      debugPrint('Post Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿に失敗しました。'))
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    switch (_currentView) {
      case CurrentView.home:
        final others = _memories.where((m) => m.authorId != _userProfile.id).toList();
        return MemoryPostScreen(
          memories: others,
          onAddComment: (id, t, a) {},
          onDeleteMemory: (id) {},
          onEditMemory: (m) {},
          onTapMemory: (memory) {
            if (!memory.discovered) {
              setState(() {
                _selectedDigTarget = memory;
                _currentView = CurrentView.dig;
              });
            }
          },
        );

      case CurrentView.mypage:
        // ★ 修正: ゲストでも「自分の投稿」を表示できるようにプレースホルダーを外す
        final my = _memories.where((m) => m.authorId == _userProfile.id).toList();
        return MemoryPostScreen(
          memories: my,
          onAddComment: (id, t, a) {},
          onDeleteMemory: (id) {},
          onEditMemory: (m) {},
          onTapMemory: (memory) {},
        );

      case CurrentView.create:
        return CreateMemoryScreen(
          // ゲストの場合は作成者名を null にして入力を促す、または「ゲスト」を初期値にする
          initialAuthor: _userProfile.id == 'guest' ? '凍土の旅人' : _userProfile.username,
          onSubmit: (String path, String text, String author, int stars) {
            _handleCreateMemory(path, text, author, stars);
          },
          onCancel: () => setState(() => _currentView = CurrentView.home),
        );

      case CurrentView.dig:
        if (_selectedDigTarget == null) return const SizedBox();
        return DiggingGameScreen(
          undiscoveredMemories: [_selectedDigTarget!],
          onDiscover: (m) {
            setState(() {
              _currentView = CurrentView.home;
              _selectedDigTarget = null;
            });
            _loadData();
          },
          onDiscoverItem: (item) {},
          dailyDigs: _dailyDigs,
          onDailyDigsChanged: (count) => setState(() => _dailyDigs = count),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMainView = (_currentView == CurrentView.home || _currentView == CurrentView.mypage);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentView == CurrentView.mypage ? '自分の記憶' : '永久凍土の記憶'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_userProfile.id == 'guest' ? Icons.login : Icons.person_outline, color: Colors.cyan),
            onPressed: () {
              if (_userProfile.id == 'guest') {
                _handleRequestSignIn();
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ProfileScreen(
                    profile: _userProfile,
                    onSave: (p) async { await _authService.signInWithUsername(p.username); _loadData(); },
                    onClose: () => Navigator.of(context).pop(),
                    onRequestSignIn: _handleRequestSignIn,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (isMainView)
              AppNavigationBar(
                currentView: _currentView,
                onViewChanged: (view) => setState(() => _currentView = view),
              ),
          ],
        ),
      ),
      floatingActionButton: isMainView
          ? FloatingActionButton(
              onPressed: () {
                // ★ 修正: 匿名(guest)でも投稿画面へ行けるようにガードを外す
                setState(() => _currentView = CurrentView.create);
              },
              backgroundColor: Colors.cyan,
              child: const Icon(Icons.add, color: Colors.black, size: 32),
            )
          : null,
    );
  }

  List<Memory> generateDebugMemories(UserProfile profile) {
    final now = DateTime.now();
    return [
      Memory(
        id: '1', photo: 'https://picsum.photos/id/10/400/400', text: '誰かの思い出',
        author: 'UserA', authorId: 'other', createdAt: now.subtract(const Duration(days: 2)),
        discovered: false, comments: [], starRating: 3,
      ),
    ];
  }
}