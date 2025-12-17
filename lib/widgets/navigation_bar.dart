// lib/widgets/navigation_bar.dart

import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // ここに CurrentView の定義がある想定

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // 中央に配置するために SingleChildScrollView ではなくシンプルな Row に変更
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
        children: <Widget>[
          _buildNavButton(
            icon: Icons.home,
            label: 'ホーム',
            view: CurrentView.home,
          ),
          const SizedBox(width: 24), // ボタン間の間隔を少し広めに
          _buildNavButton(
            icon: Icons.ac_unit,
            label: '発掘',
            view: CurrentView.dig,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required CurrentView view,
  }) {
    final isSelected = currentView == view;
    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: AnimatedContainer( // アニメーション付きにするとより心地よくなります
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? Colors.cyan 
                : Colors.cyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: isSelected ? Colors.white : Colors.cyan[100]
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.cyan[100],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}