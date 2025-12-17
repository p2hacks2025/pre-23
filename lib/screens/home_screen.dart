import 'dart:io';
import 'package:flutter/material.dart';

// モデル・サービス
import '../models/memory.dart';
import '../models/game.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/demo_data.dart'; // ★追加

// 各画面
import 'discovery_screen.dart';
import 'my_memory_list_screen.dart';
import 'create_memory_screen.dart';
import 'digging_game_screen.dart';
import 'profile_screen.dart';
import 'sign_in_screen.dart';

// ウィジェット
import '../widgets/navigation_bar.dart';
import '../widgets/memory_dialogs.dart';

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
      
      final results = await Future.wait([
        _apiService.fetchUndiscoveredMemories(profile.id),
        _apiService.fetchUserMemories(profile.id),
      ]);

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        
        // ★ Firebaseのデータが空ならデモデータを表示
        final firestoreMemories = [...results[0], ...results[1]];
        if (firestoreMemories.isEmpty) {
          _memories = DemoData.getMemories();
        } else {
          _memories = firestoreMemories;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      // ★ エラー時もデモデータを表示（開発中の安心のため）
      if (mounted) {
        setState(() {
          _memories = DemoData.getMemories();
          _isLoading = false;
        });
      }
    }
  }

  void _handleDeleteMemory(String memoryId) async {
    await _apiService.deleteMemory(memoryId);
    setState(() => _memories.removeWhere((m) => m.id == memoryId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('記憶を消去しました')));
  }

  void _handleShowReaction(Memory memory) {
    MemoryDialogs.showReaction(context, memory, (emoji) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$emoji を届けました')));
    });
  }

  Future<void> _handleCreateMemory(String path, String text, String author, int stars) async {
    await _apiService.postMemory(
      localPhotoPath: path, 
      text: text, 
      author: author, 
      authorId: _userProfile.id
    );
    await _loadData();
    if (mounted) setState(() => _currentView = CurrentView.mypage);
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.cyan));

    switch (_currentView) {
      case CurrentView.home:
        final others = _memories.where((m) => m.authorId != _userProfile.id).toList();
        return DiscoveryScreen(
          memories: others,
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
        );

      case CurrentView.mypage:
        final my = _memories.where((m) => m.authorId == _userProfile.id).toList();
        return MyMemoryListScreen(
          memories: my,
          onDeleteMemory: _handleDeleteMemory,
          onShowDetail: (memory) => MemoryDialogs.showDetail(context, memory),
        );

      case CurrentView.create:
        return CreateMemoryScreen(
          initialAuthor: _userProfile.username,
          onSubmit: _handleCreateMemory,
          onCancel: () => setState(() => _currentView = CurrentView.home),
        );

      case CurrentView.dig:
        if (_selectedDigTarget == null) return const SizedBox();
        return DiggingGameScreen(
          undiscoveredMemories: [_selectedDigTarget!],
          onDiscover: (m) async {
            // デモデータ(IDにdemo_を含む)の場合はAPIを呼ばない
            if (!m.id.startsWith('demo_')) {
              await _apiService.discoverMemory(m, _userProfile.id);
            }

            setState(() {
              final index = _memories.indexWhere((element) => element.id == m.id);
              if (index != -1) {
                _memories[index].discovered = true;
              }
              _currentView = CurrentView.home;
              _selectedDigTarget = null;
            });
          },
          onDiscoverItem: (item) => _apiService.discoverItem(item, _userProfile.id),
          dailyDigs: _dailyDigs,
          onDailyDigsChanged: (c) => setState(() => _dailyDigs = c),
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
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _userProfile.id == 'guest' ? Icons.login : Icons.person_outline, 
              color: Colors.cyan
            ),
            onPressed: _handleRequestSignIn,
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
              onPressed: () => setState(() => _currentView = CurrentView.create),
              backgroundColor: Colors.cyan,
              child: const Icon(Icons.add, color: Colors.black, size: 32),
            )
          : null,
    );
  }

  void _handleRequestSignIn() {
    showDialog(
      context: context,
      builder: (context) => SignInScreen(
        onSignedIn: (profile) async {
          await _loadData();
          if (mounted) Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}