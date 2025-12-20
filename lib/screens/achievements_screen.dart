import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/effects.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return FutureBuilder<UserProfile?>(
      future: auth.getCurrentUser(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }

        final userId = authSnapshot.data!.id;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('userProfiles')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyan));
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

            // 統計データの取得（コメントカウントを削除）
            final stats = {
              'digCount': data['totalDigs'] ?? 0,
              'sendStampCount': data['sendStampCount'] ?? 0,
              'beenDugCount': data['beenDugCount'] ?? 0,
              'receiveStampCount': data['receiveStampCount'] ?? 0,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'あなたの功績',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // 1. 発掘の実績
                  _buildCategorySection(
                    context,
                    "記憶を紐解いた歩み",
                    "他人の氷を解いた数",
                    stats['digCount']!,
                    ["記憶の糸口", "思い出の解凍者", "物語を綴る風", "時を識る旅人"],
                    Icons.auto_fix_high,
                  ),

                  // 2. キラキラを贈った実績
                  _buildCategorySection(
                    context,
                    "分け与えた慈しみ",
                    "キラキラを贈った数",
                    stats['sendStampCount']!,
                    ["ひとひらの輝き", "光の蒐集家", "記憶を照らす月", "永遠の星巡り"],
                    Icons.flare,
                  ),

                  // 3. 自分の投稿が掘られた実績
                  _buildCategorySection(
                    context,
                    "誰かに触れられた記憶",
                    "自分の氷が解かれた数",
                    stats['beenDugCount']!,
                    ["目覚めるささやき", "透き通る結晶", "氷原の道標", "不滅の情景"],
                    Icons.cloud_queue,
                  ),

                  // 4. キラキラを貰った実績
                  _buildCategorySection(
                    context,
                    "心に届いた共鳴",
                    "キラキラを贈られた数",
                    stats['receiveStampCount']!,
                    ["届いた光", "彩りの記憶", "心に降る銀河", "世界の灯火"],
                    Icons.auto_awesome,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- _buildCategorySection 以下のメソッドは以前のコードを維持 ---
  Widget _buildCategorySection(
    BuildContext context,
    String title,
    String subtitle,
    int count,
    List<String> titles,
    IconData icon,
  ) {
    final thresholds = [1, 30, 100, 300];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: IceEffects.glassStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(4, (index) {
                bool isUnlocked = count >= thresholds[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.cyan.withOpacity(0.15)
                          : Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnlocked
                            ? Colors.cyan.withOpacity(0.6)
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      titles[index],
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white24,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          _buildEnhancedProgressBar(count, thresholds),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressBar(int count, List<int> thresholds) {
    int nextThreshold = thresholds.firstWhere((t) => t > count, orElse: () => 0);
    bool isMax = nextThreshold == 0;
    double progressValue;
    if (isMax) {
      progressValue = 1.0;
    } else {
      int prevThreshold = thresholds.lastWhere((t) => t <= count, orElse: () => 0);
      progressValue = (count - prevThreshold) / (nextThreshold - prevThreshold);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              isMax ? "$count / Max" : "$count / $nextThreshold",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 4,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressValue.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyan, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.cyan.withOpacity(0.3), blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}