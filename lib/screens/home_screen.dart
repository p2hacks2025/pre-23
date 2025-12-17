import 'package:flutter/material.dart';

// モデル・サービス
import '../models/memory.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// 各画面
import 'create_memory_screen.dart';
import 'digging_game_screen.dart';
import 'sign_in_screen.dart';

// ウィジェット
import '../widgets/navigation_bar.dart';
import '../widgets/memory_dialogs.dart';
import '../widgets/memory_list_view.dart';

enum CurrentView { home, mypage, create, dig }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ★変更: 初期値を設定
  CurrentView _currentView = CurrentView.home;
  
  // ★追加: ページ切り替え用のコントローラー
  late PageController _pageController;

  Memory? _selectedDigTarget;
  bool _isLoading = true;
  bool _isPosting = false; 
  int _dailyDigs = 3;

  UserProfile _userProfile = UserProfile(id: 'guest', username: 'ゲスト', avatar: '', bio: '');
  List<Memory> _memories = [];

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool get _isGuest => _userProfile.id == 'guest';

  @override
  void initState() {
    super.initState();
    // ★追加: PageControllerの初期化
    _pageController = PageController(initialPage: 0);
    _loadData();
  }

  @override
  void dispose() {
    // ★追加: コントローラーの破棄
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final profile = await _authService.getCurrentUser();
      
      final results = await Future.wait([
        _apiService.fetchUndiscoveredMemories(profile.id),
        _apiService.fetchUserMemories(profile.id),
      ]);

      if (!mounted) return;
      
      setState(() {
        _userProfile = profile;
        final allMemories = [...results[0], ...results[1]];
        final ids = <String>{};
        _memories = allMemories.where((m) => ids.add(m.id)).toList();
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _memories = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データの読み込みに失敗しました')),
        );
      }
    }
  }

  void _handleDeleteMemory(String memoryId) async {
    try {
      await _apiService.deleteMemory(memoryId);
      setState(() => _memories.removeWhere((m) => m.id == memoryId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('記憶を消去しました')));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  void _handleShowReaction(Memory memory) {
    if (_isGuest) {
      _handleRequestSignIn();
      return;
    }

    MemoryDialogs.showReaction(context, memory, (emoji) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$emoji を届けました')));
    });
  }

  Future<void> _handleCreateMemory(String path, String text, String author, int stars) async {
    setState(() => _isPosting = true);

    try {
      final result = await _apiService.postMemory(
        localPhotoPath: path, 
        text: text, 
        author: author, 
        authorId: _userProfile.id,
        starRating: stars,
      );

      if (result == null) {
        if (mounted) {
          setState(() => _isPosting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('写真のアップロードに失敗しました。\n通信環境または権限を確認してください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
      await _loadData();

      if (mounted) {
        setState(() {
          _isPosting = false;
          // 投稿後はマイページへ移動（ページ遷移アニメーション付き）
          _currentView = CurrentView.mypage;
          _pageController.jumpToPage(1); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記憶を投稿しました')),
        );
      }
    } catch (e) {
      debugPrint('Post error: $e');
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予期せぬエラーが発生しました')),
        );
      }
    }
  }
  
  void _handleRequestSignIn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SignInScreen(
        onSignedIn: (profile) async {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ようこそ、${profile.username}さん')),
            );
          }
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしてゲストに戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              await _loadData();
              // ログアウトしたらホームに戻す
              if (mounted) {
                setState(() {
                  _currentView = CurrentView.home;
                  _pageController.jumpToPage(0);
                });
              }
            },
            child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ★追加: ホーム画面（みんなの記憶）の構築ロジックを分離
  Widget _buildHomeView() {
    final others = _memories.where((m) => m.authorId != _userProfile.id).toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.cyan,
      child: MemoryListView(
        memories: others,
        type: MemoryListType.discovery, 
        onTapMemory: (memory) {
          if (!memory.discovered) {
            setState(() {
              _selectedDigTarget = memory;
              _currentView = CurrentView.dig;
            });
          } else {
            _handleShowReaction(memory);
          }
        },
      ),
    );
  }

  // ★追加: マイページ画面の構築ロジックを分離
  Widget _buildMyPageView() {
    final my = _memories.where((m) => m.authorId == _userProfile.id).toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.cyan,
      child: MemoryListView(
        memories: my,
        type: MemoryListType.grid,
        onTapMemory: (memory) => MemoryDialogs.showDetail(context, memory),
        onDeleteMemory: _handleDeleteMemory,
      ),
    );
  }

  // ★変更: _buildBody を大幅修正
  Widget _buildBody() {
    if (_isLoading || _isPosting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.cyan),
            SizedBox(height: 16),
            Text('データを同期中...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    // 作成モード、発掘モードの場合は、PageViewではなくその画面を直接表示
    if (_currentView == CurrentView.create) {
      return CreateMemoryScreen(
        initialAuthor: _userProfile.username,
        onSubmit: _handleCreateMemory,
        onCancel: () => setState(() {
          _currentView = CurrentView.home;
          _pageController.jumpToPage(0); // キャンセル時はホームへ
        }),
      );
    }

    if (_currentView == CurrentView.dig) {
      if (_selectedDigTarget == null) return const SizedBox();
      return DiggingGameScreen(
        undiscoveredMemories: [_selectedDigTarget!],
        isGuest: _isGuest,
        onRequestLogin: _handleRequestSignIn,
        onDiscover: (m) async {
          if (!_isGuest) {
            await _apiService.discoverMemory(m, _userProfile.id);
          }
          if (!mounted) return;
          setState(() {
            final index = _memories.indexWhere((element) => element.id == m.id);
            if (index != -1) {
              _memories[index].discovered = true;
            }
            // 発掘が終わったらホームに戻る
            _currentView = CurrentView.home;
            _selectedDigTarget = null;
            // PageViewもホーム位置へ戻す
            if (_pageController.hasClients) {
              _pageController.jumpToPage(0);
            }
          });
        },
        onDiscoverItem: (item) {
           if (!_isGuest) _apiService.discoverItem(item, _userProfile.id);
        },
        dailyDigs: _dailyDigs,
        onDailyDigsChanged: (c) => setState(() => _dailyDigs = c),
      );
    }

    // ★重要: 通常時は PageView を表示してスワイプ可能にする
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          // スワイプされたら _currentView を更新
          _currentView = index == 0 ? CurrentView.home : CurrentView.mypage;
        });
      },
      children: [
        _buildHomeView(),   // Page 0
        _buildMyPageView(), // Page 1
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMainView = (_currentView == CurrentView.home || _currentView == CurrentView.mypage);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentView == CurrentView.mypage ? '自分の記憶' : '永久凍土の記憶'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isGuest ? Icons.login : Icons.person, 
              color: Colors.cyan
            ),
            onPressed: () {
              if (_isGuest) {
                _handleRequestSignIn();
              } else {
                _handleSignOut();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            // ナビゲーションバーは、CreateやDigモード以外で表示
            if (isMainView)
              AppNavigationBar(
                currentView: _currentView,
                onViewChanged: (view) {
                  setState(() {
                    _currentView = view;
                    // ★追加: アイコンタップ時にページをスライドさせる
                    if (view == CurrentView.home) {
                      _pageController.animateToPage(
                        0, 
                        duration: const Duration(milliseconds: 300), 
                        curve: Curves.easeOut
                      );
                    } else if (view == CurrentView.mypage) {
                      _pageController.animateToPage(
                        1, 
                        duration: const Duration(milliseconds: 300), 
                        curve: Curves.easeOut
                      );
                    }
                  });
                },
              ),
          ],
        ),
      ),
      floatingActionButton: isMainView
          ? FloatingActionButton(
              onPressed: () {
                if (_isGuest) {
                  _handleRequestSignIn();
                } else {
                  setState(() => _currentView = CurrentView.create);
                }
              },
              backgroundColor: Colors.cyan,
              child: const Icon(Icons.add, color: Colors.black, size: 32),
            )
          : null,
    );
  }
}