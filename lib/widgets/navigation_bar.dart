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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      // 背面を少し透過させて、氷の世界観を出す
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
          children: <Widget>[
            // 1. ホームボタン
            _buildNavButton(
              icon: Icons.home_filled,
              view: CurrentView.home,
            ),
            const SizedBox(width: 24), // ボタン間の余白
            // 2. マイページボタン
            _buildNavButton(
              icon: Icons.person_rounded,
              view: CurrentView.mypage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required CurrentView view,
  }) {
    // 選択状態の判定
    // CurrentView.create（投稿画面）のときは、ホームを光らせるようにしています
    final isSelected = (currentView == view) || 
                       (view == CurrentView.home && currentView == CurrentView.create);
    
    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.white10,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Icon(
          icon, 
          size: 24, 
          color: isSelected ? Colors.white : Colors.white70
        ),
      ),
    );
  }
}