import 'package:flutter/material.dart';
// CurrentViewの定義場所に合わせてimportしてください
// もし home_screen.dart にある場合は循環参照になるため、
// lib/models/enums.dart など別ファイルに Enum を移動することをお勧めします。
import '../screens/home_screen.dart'; 

class AppNavigationBar extends StatelessWidget {
  final CurrentView currentView;
  final ValueChanged<CurrentView> onViewChanged;

  const AppNavigationBar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 現在のViewからインデックスを逆算
    // (Create画面はバーに含まないので、Home扱いまたは選択なしにする)
    int currentIndex = 0;
    switch (currentView) {
      case CurrentView.home:
      case CurrentView.create: // 投稿画面の時もホームのアイコンを光らせておくか、0にする
        currentIndex = 0;
        break;
      case CurrentView.dig:
        currentIndex = 1;
        break;
      case CurrentView.collection:
        currentIndex = 2;
        break;
      case CurrentView.achievements:
        currentIndex = 3;
        break;
    }

    return Container(
      // 上に境界線を入れる（任意）
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        // ★重要: これでアイコンが等間隔に固定されます（スクロールしなくなる）
        type: BottomNavigationBarType.fixed,
        
        // ★重要: これで文字ラベルを非表示にします
        showSelectedLabels: false,
        showUnselectedLabels: false,

        // 色設定（世界観に合わせて黒背景・シアン選択色）
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey.shade700,
        
        // アイコンサイズ調整（少し大きめの方が見やすい）
        iconSize: 28,
        
        currentIndex: currentIndex,
        onTap: (index) {
          // インデックスからViewへの変換
          switch (index) {
            case 0:
              onViewChanged(CurrentView.home);
              break;
            case 1:
              onViewChanged(CurrentView.dig);
              break;
            case 2:
              onViewChanged(CurrentView.collection);
              break;
            case 3:
              onViewChanged(CurrentView.achievements);
              break;
          }
        },
        items: const [
          // 1. ホーム
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled), // Instagramっぽい中塗りのホーム
            label: 'Home', // showLabels: false なので表示されませんが、識別用に記述
          ),
          
          // 2. 発掘 (ツルハシや冒険っぽいアイコン)
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore), 
            label: 'Dig',
          ),

          // 3. コレクション (グリッド表示)
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), 
            label: 'Collection',
          ),

          // 4. 実績 (トロフィー)
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events), 
            label: 'Trophies',
          ),
        ],
      ),
    );
  }
}