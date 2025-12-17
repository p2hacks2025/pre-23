import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // CurrentView の定義を読み込む

class AppNavigationBar extends StatelessWidget {
  final CurrentView currentView;
  final Function(CurrentView) onViewChanged;

  const AppNavigationBar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 現在のViewからインデックスを決定
    // 0: Home, 1: MyPage
    int currentIndex = 0;
    if (currentView == CurrentView.mypage) {
      currentIndex = 1;
    } else {
      // home, create, dig などは基本Homeタブのアクティブ状態とする
      currentIndex = 0;
    }

    return Container(
      decoration: const BoxDecoration(
        // 上部に薄い境界線を入れて区切りを明確にする
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        
        // ラベルを表示せずアイコンのみにする設定
        showSelectedLabels: false,
        showUnselectedLabels: false,
        
        // 配色設定 (参考コードに準拠)
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey.shade700,
        iconSize: 30, // タップしやすいサイズに調整
        
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              onViewChanged(CurrentView.home);
              break;
            case 1:
              onViewChanged(CurrentView.mypage);
              break;
          }
        },
        items: const [
          // 1. ホーム (みんなの記憶)
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          
          // 2. マイページ (自分の記憶)
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'My Page',
          ),
        ],
      ),
    );
  }
}