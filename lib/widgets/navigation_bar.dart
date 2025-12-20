import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
// lib/widgets/navigation_bar.dart
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(Icons.auto_fix_high, CurrentView.discovery, '発掘'),
          _buildNavButton(Icons.home_rounded, CurrentView.home, 'ホーム'),
          _buildNavButton(Icons.emoji_events_rounded, CurrentView.achievements, '実績'),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, CurrentView view, String label) {
    final isSelected = currentView == view;
    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.cyan : Colors.white38,
            size: isSelected ? 30 : 26,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.cyan : Colors.white38,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}