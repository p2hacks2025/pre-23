// lib/widgets/navigation_bar.dart

import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class AppNavigationBar extends StatelessWidget {
  final CurrentView currentView;
  final Function(CurrentView) onViewChanged;
  // final bool hideCreateButton; // ←削除しました

  const AppNavigationBar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    // this.hideCreateButton = false, // ←削除しました
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildNavButton(
                icon: Icons.home,
                label: 'ホーム',
                view: CurrentView.home,
              ),
              // ▼▼▼ 「封印」ボタンを削除しました ▼▼▼
              const SizedBox(width: 12),
              _buildNavButton(
                icon: Icons.ac_unit,
                label: '発掘',
                view: CurrentView.dig,
              ),
              const SizedBox(width: 12),
              _buildNavButton(
                icon: Icons.inventory_2,
                label: 'コレクション',
                view: CurrentView.collection,
              ),
              const SizedBox(width: 12),
              _buildNavButton(
                icon: Icons.emoji_events,
                label: '実績',
                view: CurrentView.achievements,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required CurrentView view,
  }) {
    // hideCreateButtonの判定ロジックも削除しました
    
    final isSelected = currentView == view;
    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                )
              : null,
          color: isSelected ? null : Colors.white.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.cyan.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.cyan[100]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.cyan[100],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}