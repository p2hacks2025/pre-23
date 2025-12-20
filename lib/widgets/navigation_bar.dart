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
    // 現在のViewからインデックスを逆算（アニメーション等の制御用）
    int currentIndex = 0;
    switch (currentView) {
      case CurrentView.discovery:
        currentIndex = 0;
        break;
      case CurrentView.home:
        currentIndex = 1;
        break;
      case CurrentView.achievements:
        currentIndex = 2;
        break;
    }

    return Container(
      // 背景を少し透過させてキラキラが見えるようにする
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // 0.5から0.3に下げるとより綺麗です
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
      behavior: HitTestBehavior.opaque, // タップ反応を良くする
      onTap: () => onViewChanged(view),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.cyan : Colors.white38,
            size: isSelected ? 30 : 26,
          ),
          const SizedBox(height: 4), // 少し間隔をあける
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