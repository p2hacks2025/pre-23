import 'package:flutter/material.dart';
import '../models/game.dart';

class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;
  final int totalDigs;

  const AchievementsScreen({
    super.key,
    required this.achievements,
    required this.totalDigs,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = achievements.where((a) => a.completed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '実績',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyan.withAlpha(51),
                  Colors.blue.withAlpha(51),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.cyan.withAlpha(77)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / ${achievements.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '達成した実績',
                      style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalDigs',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '総発掘回数',
                      style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Achievements List
          ...achievements.map((achievement) => _buildAchievementCard(achievement)),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final progressPercent = (achievement.progress / achievement.requirement).clamp(0.0, 1.0) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.withAlpha(51),
            Colors.blue.withAlpha(51),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: achievement.completed
              ? Colors.amber.withAlpha(128)
              : Colors.cyan.withAlpha(77),
          width: achievement.completed ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement.icon,
            style: TextStyle(
              fontSize: 48,
              color: achievement.completed ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achievement.completed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withAlpha(128)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '達成',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '進捗',
                      style: TextStyle(color: Colors.cyan[300], fontSize: 12),
                    ),
                    Text(
                      '${achievement.progress} / ${achievement.requirement}',
                      style: TextStyle(color: Colors.cyan[300], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                    value: progressPercent / 100,
                    minHeight: 8,
                    backgroundColor: Colors.cyan.shade900.withAlpha(128),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.completed
                          ? Colors.amber
                          : Colors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

