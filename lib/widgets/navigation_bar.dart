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
    int currentIndex = 0;
    switch (currentView) {
      case CurrentView.home:
      case CurrentView.create:
        currentIndex = 0;
        break;
      case CurrentView.dig:
        currentIndex = 1;
        break;
      // コレクション削除に伴い、実績を 2 に繰り上げ
      case CurrentView.achievements:
        currentIndex = 2;
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey.shade700,
        iconSize: 28,
        
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              onViewChanged(CurrentView.home);
              break;
            case 1:
              onViewChanged(CurrentView.dig);
              break;
            case 2:
              // 実績画面へ
              onViewChanged(CurrentView.achievements);
              break;
          }
        },
        items: const [
          // 1. ホーム
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          
          // 2. 発掘
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore), 
            label: 'Dig',
          ),

          // 3. 実績 (コレクションを削除し、ここが3番目になります)
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events), 
            label: 'Trophies',
          ),
        ],
      ),
    );
  }
}