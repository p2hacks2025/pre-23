import 'dart:math';
import 'package:flutter/material.dart';

import '../models/memory.dart';
import '../models/game.dart'; 
import '../services/storage_service.dart';
//kakuninn

// セル状態の定義 (変更なし)
enum CellState { frozen, cracking, melted, found }

class DiggingGameScreen extends StatefulWidget {
  final List<Memory> undiscoveredMemories;
  final Function(Memory) onDiscover;
  final Function(Item) onDiscoverItem;
  final int dailyDigs;
  final Function(int) onDailyDigsChanged;
  
  const DiggingGameScreen({
    super.key,
    required this.undiscoveredMemories,
    required this.onDiscover,
    required this.onDiscoverItem,
    required this.dailyDigs,
    required this.onDailyDigsChanged,
  });

  @override
  State<DiggingGameScreen> createState() => _DiggingGameScreenState();
}

class _DiggingGameScreenState extends State<DiggingGameScreen>
    with TickerProviderStateMixin {
  static const int gridCols = 4;
  static const int gridRows = 4;
  static const int gridSize = gridCols * gridRows;
  static const double _customHeaderHeight = 90.0; // ヘッダーの高さを微増

  late List<CellState> _cellStates;
  final Map<int, AnimationController> _breakControllers = {};
  late AnimationController _resultController;
  final StorageService _storageService = StorageService();

  bool _isDigging = false;
  dynamic _discovered;

  int? _hiddenMemoryIndex;
  //int? _hiddenItemIndex;

  int _bonusDigs = 0;
  
  @override
  void initState() {
    super.initState();
    _cellStates = List<CellState>.filled(gridSize, CellState.frozen);
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bonusDigs = 0;
    _setupHidden();
  }

  @override
  void dispose() {
    for (final c in _breakControllers.values) {
      c.dispose();
    }
    _resultController.dispose();
    super.dispose();
  }

  // --- ロジック関数 (変更なし) ---
  void _setupHidden() {
    final rnd = Random();
    _cellStates = List<CellState>.filled(gridSize, CellState.frozen);
    final indices = List<int>.generate(gridSize, (i) => i)..shuffle(rnd);
    // 1. 記憶の断片の配置
    // 未発見の記憶がある限り、必ず一つのセルに記憶を隠します。
    _hiddenMemoryIndex = indices.isNotEmpty && widget.undiscoveredMemories.isNotEmpty
        ? indices.removeLast()
        : null;
    //_hiddenItemIndex = indices.isNotEmpty && rnd.nextDouble() < 0.6
        //? indices.removeLast()
        //: null;
  }

  Future<void> _dig(int idx) async {
    // 既に掘ったセル、または発掘中の場合は何もしない
    if (_isDigging || _cellStates[idx] != CellState.frozen) return;
    
    // 発掘回数がゼロなら、即座にダイアログを表示して終了
    if (widget.dailyDigs + _bonusDigs <= 0) {
      await _showDailyDigsEndDialog();
      return; 
    }

    setState(() => _isDigging = true);

    AnimationController? ctrl;
    try {
      // クラッキングアニメーション
      setState(() => _cellStates[idx] = CellState.cracking);
      ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 50));
      _breakControllers[idx] = ctrl;
      await ctrl.forward();
      await Future.delayed(const Duration(milliseconds: 10));

      bool found = false;
      Memory? foundMemory;
      //Item? foundItem;

      if (idx == _hiddenMemoryIndex) {
        Memory? m;
        // 未発見の記憶がない場合を考慮 (通常は_setupHiddenで防止されるが安全のため)
        if (widget.undiscoveredMemories.isNotEmpty) m = widget.undiscoveredMemories.removeAt(0); 
        if (m != null) {
          found = true;
          foundMemory = m;
        }
      }

      if (found) {
        // 【発見時のロジック: 回数消費、状態更新、永続化、実績更新】
        setState(() {
          _cellStates[idx] = CellState.found;
          _discovered = foundMemory;
          _hiddenMemoryIndex = foundMemory != null ? null : _hiddenMemoryIndex;
          //_hiddenItemIndex = foundItem != null ? null : _hiddenItemIndex;

        
        });
        
        // 永続化 & コールバック
        try {
          if (foundMemory != null) {
            widget.onDiscover(foundMemory);
            final current = await _storageService.getDiscoveredMemories();
            final updated = [...current, foundMemory.copyWith(discovered: true)];
            await _storageService.saveDiscoveredMemories(updated);
          }
          // 累積発掘回数と実績の更新
          final total = await _storageService.getTotalDigs();
          await _storageService.saveTotalDigs(total + 1);
          await _updateAchievements(null, foundMemory);
          
          // 発掘回数削減ロジック（ボーナス優先）
          final nextRemaining = (widget.dailyDigs - 1).clamp(0, 9999);
          widget.onDailyDigsChanged(nextRemaining);
          
          final data = await _storageService.getDailyDigData();
          final today = DateTime.now().toIso8601String().split('T')[0];
          final newUsed = (data['used'] as int) + 1;
          await _storageService.saveDailyDigData(today, nextRemaining, newUsed);

        } catch (e) {
          debugPrint('永続化エラー: $e');
        }
        
        _resultController.forward();
      } else {
        // 空振り時のロジック: 回数消費なし、セルを溶かす
        setState(() => _cellStates[idx] = CellState.melted);
      }

      // アニメーションコントローラーのクリーンアップ
      ctrl.dispose();
      _breakControllers.remove(idx);

    } finally {
      setState(() => _isDigging = false);
    }
  }

  Future<void> _updateAchievements(Item? item, Memory? memory) async {
    try {
      final achievements = await _storageService.getAchievements();
      bool changed = false;
      
      // 1. 記憶の断片 (memoryCount) の更新
      if (memory != null) {
        final discoveredMemories = await _storageService.getDiscoveredMemories();
        final memoryCount = discoveredMemories.length;
        for (var a in achievements.where((a) => a.type == AchievementType.memoryCount)) {
          if (!a.completed) {
            final newProgress = min(memoryCount, a.requirement);
            if (newProgress > a.progress) {
              achievements[achievements.indexOf(a)] = a.copyWith(
                progress: newProgress,
                completed: newProgress == a.requirement
              );
              changed = true;
            }
          }
        }
      }

      // 2. アイテム関連 (legendaryCount, gemCount, bottleCount) の更新
      /*if (item != null) {
        final allItems = await _storageService.getItems();
        
        // Legendary Count
        final legendaryCount = allItems.where((i) => i.rarity == Rarity.legendary).length;
        for (var a in achievements.where((a) => a.type == AchievementType.legendaryCount)) {
          if (!a.completed) {
            final newProgress = min(legendaryCount, a.requirement);
            if (newProgress > a.progress) {
              achievements[achievements.indexOf(a)] = a.copyWith(
                progress: newProgress,
                completed: newProgress == a.requirement
              );
              changed = true;
            }
          }
        }
        
        // Item Type Counts (gemCount, bottleCount)
        final itemTypeCounts = <AchievementType, int>{};
        // ✅ 修正: 累積アイテム数を使って実績進捗を更新
        final allGems = allItems.where((i) => i.type == ItemType.gem).length;
        final allBottles = allItems.where((i) => i.type == ItemType.bottle).length;
        // 👇 ここに、カウントをマップに設定する処理を追加します
        itemTypeCounts[AchievementType.gemCount] = allGems;
        itemTypeCounts[AchievementType.bottleCount] = allBottles;
        

        for (var a in achievements.where((a) => a.type == AchievementType.gemCount || a.type == AchievementType.bottleCount)) {
          if (!a.completed) {
            final currentCount = itemTypeCounts[a.type] ?? 0;
            final newProgress = min(currentCount, a.requirement);
            if (newProgress > a.progress) {
              achievements[achievements.indexOf(a)] = a.copyWith(
                progress: newProgress,
                completed: newProgress == a.requirement
              );
              changed = true;
            }
          }
        }
      }*/

      if (changed) {
        await _storageService.saveAchievements(achievements);
      }
    } catch (e) {
      debugPrint('実績更新エラー: $e');
    }
  }

  int _getBonusDigsForRarity(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 0;
      case Rarity.rare:
        return 1;
      case Rarity.epic:
        return 2;
      case Rarity.legendary:
        return 3;
    }
  }

 /* Item _makeItem() {
    final rnd = Random();
    final roll = rnd.nextDouble();
    final rarity = roll > 0.95
        ? Rarity.legendary
        : roll > 0.8
            ? Rarity.epic
            : roll > 0.5
                ? Rarity.rare
                : Rarity.common;

    final types = ItemType.values;
    final type = types[rnd.nextInt(types.length)];

    return Item(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: '古びた遺物 (${_getRarityLabel(rarity)})',
      description: '歴史の断片',
      rarity: rarity,
      image: 'https://picsum.photos/80',
      discoveredAt: DateTime.now(),
    );
  }*/

  String _getRarityLabel(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 'コモン';
      case Rarity.rare:
        return 'レア';
      case Rarity.epic:
        return 'エピック';
      case Rarity.legendary:
        return 'レジェンダリー';
    }
  }

  Future<void> _showDailyDigsEndDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('発掘終了'),
        content: const Text('本日の発掘回数（ボーナス含む）はすべて使い切りました。明日またお会いしましょう！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    for (final c in _breakControllers.values) {
      c.dispose();
    }
    _breakControllers.clear();
    
    _resultController.reset();
    _isDigging = false;
    
    setState(() {
      _discovered = null; 
      _setupHidden();
    });
    
    final total = widget.dailyDigs + _bonusDigs;
    if (total <= 0) {
      _showDailyDigsEndDialog();
    }
  }
  
  // --------------------------------------------------------------------------
  // 🚀 UI修正 1: ファンタジー要素を強めたカスタムヘッダー
  // --------------------------------------------------------------------------
  Widget _buildCustomHeader(double width) {
    return Container(
      height: _customHeaderHeight,
      width: width,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // メタリックな青色グラデーション
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        // 魔法陣風のボーダー
        border: Border.all(color: Colors.cyan.shade300, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.ac_unit, color: Colors.cyanAccent, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '永久凍土発掘所',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  '時を超えた記憶を探し出せ',
                  style: TextStyle(color: Colors.cyan.shade200, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🚀 UI修正 2: セルデザインの変更 (凍土タイル風)
  // --------------------------------------------------------------------------
  Widget _cell(int idx) {
    final st = _cellStates[idx];
    final ctrl = _breakControllers[idx];
    final av = ctrl != null ? ctrl.value : 0.0;

    Color bg;
    Color borderColor;
    double elevation = 3.0;
    Widget ico;
    
    switch (st) {
      case CellState.frozen:
        // 深く凍った氷のブロック
        bg = Color.lerp(const Color(0xFF6785A3), const Color(0xFF90a4ae), av)!; // わずかにアニメーション
        borderColor = Colors.white.withOpacity(0.6);
        ico = const Icon(Icons.layers_clear, color: Colors.white70, size: 24);
        elevation = 5.0;
        break;
      case CellState.cracking:
        // 砕けるアニメーション
        final v = av;
        if (v < 0.5) {
          bg = Color.lerp(const Color(0xFF90a4ae), Colors.yellow.shade50, v * 2)!;
        } else {
          bg = Color.lerp(Colors.yellow.shade50, const Color(0xFFffeb3b), (v - 0.5) * 2)!;
        }
        borderColor = Colors.amber;
        ico = Transform.scale(
          scale: 1.0 + (av * 0.4),
          child: const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 28), // 融解を示す炎
        );
        elevation = 8.0;
        break;
      case CellState.melted:
        // 掘り起こされた泥や水たまり
        bg = const Color(0xFF263238);
        borderColor = const Color(0xFF455a64);
        ico = const Icon(Icons.water, color: Colors.blueGrey, size: 24);
        elevation = 1.0;
        break;
      case CellState.found:
        // 発見場所
        bg = Colors.amber.shade700;
        borderColor = Colors.yellow.shade300;
        ico = const Icon(Icons.star_rounded, color: Colors.white, size: 30);
        elevation = 6.0;
        break;
    }

    return GestureDetector(
      onTap: () => _dig(idx),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
            // 凍土の光沢
            if (st == CellState.frozen)
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(child: ico),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🚀 UI修正 3: 発見ポップアップの豪華化
  // --------------------------------------------------------------------------
 Widget _buildDiscoveryPopup(double w) {
    // final discoveredItem = _discovered is Item ? _discovered as Item : null; // 👈 削除
    final discoveredMemory = _discovered is Memory ? _discovered as Memory : null;
    // final isItem = discoveredItem != null; // 👈 削除。常に false になる
    
    // discoveredMemory が null の場合は表示しない（_dig ロジックで制御されているはず）
    if (discoveredMemory == null) return const SizedBox.shrink(); 

    // isItem のフラグを削除し、記憶発見用UIに固定
    const isItem = false; 

    return Container(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
          child: Container(
            width: min(350.0, w - 40),
            padding: const EdgeInsets.all(24),
            // 背景を記憶発見用に固定
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.indigo.shade800, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyan.shade300, 
                width: 3
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // タイトルを記憶発見用に固定
                const Text(
                  '🌟 記憶の断片解放!', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)
                ),
                const SizedBox(height: 16),
                
                // 画像を記憶のアイコンに固定
                const Icon(Icons.history_edu, size: 80, color: Colors.cyanAccent),
                const SizedBox(height: 12),
                
                // 発見された記憶のテキストを表示
                Text(
                  discoveredMemory.text.length > 50 ? '${discoveredMemory.text.substring(0, 50)}...' : discoveredMemory.text, 
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                
                // アイテムボーナス表示部分を削除
                // if (isItem && _getBonusDigsForRarity(discoveredItem.rarity) > 0) ...[] // 👈 削除
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _reset, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan, // 色を記憶発見用に固定
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('閉じる/次を掘る', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.dailyDigs + _bonusDigs;
    
    return Container(
      // 🚀 UI修正 4: 画面全体の背景をファンタジー風グラデーションに
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.indigo.shade900,
            Colors.black87,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: LayoutBuilder(builder: (context, cons) {
        final w = cons.maxWidth;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // カスタムヘッダーの配置
                  _buildCustomHeader(w),
                  
                  // 発掘情報ヘッダー (位置を下に移動)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('発掘フィールド', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            // 🚀 UI修正 5: 発掘回数の表示をリッチに
                            Row(
                              children: [
                                const Icon(Icons.flash_on, color: Colors.yellow, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '残り: ${widget.dailyDigs}', 
                                  style: const TextStyle(fontSize: 14, color: Colors.white70)
                                ),
                                if (_bonusDigs > 0) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star, color: Colors.amberAccent, size: 16),
                                  Text(' (+ボーナス$_bonusDigs)', style: const TextStyle(fontSize: 14, color: Colors.amberAccent)),
                                ],
                              ],
                            ),
                          ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Grid が画面に収まるようにサイズを制御
                    Expanded(
                  child: Center(
                    child: AspectRatio( // Grid全体を正方形に保つ
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade800.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(8),
                        // width/heightの固定指定は削除

                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( // const を追加
                            crossAxisCount: gridCols,
                            childAspectRatio: 1.0,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: gridSize,
                          itemBuilder: (_, i) => _cell(i), // ✅ 修正: cszを渡さない
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDigging || _discovered == null ? null : _reset, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('リセットして次を掘る', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          // 🚀 UI修正 6: 発掘回数表示をヘッダーの下に移動
          // 元のPositionedのウィジェットは削除しました。発掘情報ヘッダーに統合しています。

          // 🚀 UI修正 7: ポップアップをカスタムウィジェットに置き換え
          if (_discovered != null)
            Positioned.fill(
              child: _buildDiscoveryPopup(w),
            ),
        ],
        );
      })
    );
  }
}