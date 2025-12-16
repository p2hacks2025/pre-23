import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';

class CollectionScreen extends StatelessWidget {
  final List<Item> items;

  const CollectionScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final sortedItems = List<Item>.from(items)
      ..sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));

    final stats = {
      'total': items.length,
      'gems': items.where((i) => i.type == ItemType.gem).length,
      'barrels': items.where((i) => i.type == ItemType.barrel).length,
      'bottles': items.where((i) => i.type == ItemType.bottle).length,
      'glasses': items.where((i) => i.type == ItemType.glass).length,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'コレクション',
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
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatCard('${stats['total']}', '総アイテム数'),
                _buildStatCard('💎', '${stats['gems']}'),
                _buildStatCard('🛢️', '${stats['barrels']}'),
                _buildStatCard('🍾', '${stats['bottles']}'),
                _buildStatCard('🍺', '${stats['glasses']}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Items Grid
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.cyan.withAlpha(51)),
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ac_unit, size: 64, color: Colors.cyan),
                  const SizedBox(height: 16),
                  const Text(
                    'まだアイテムを発掘していません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '発掘を始めてコレクションを増やしましょう！',
                    style: TextStyle(color: Colors.cyan[300], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                return _buildItemCard(sortedItems[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.cyan[300],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildItemCard(Item item) {
    final rarityColors = {
      Rarity.common: [Colors.grey[400]!, Colors.grey[600]!],
      Rarity.rare: [Colors.blue[400]!, Colors.blue[600]!],
      Rarity.epic: [Colors.purple[400]!, Colors.purple[600]!],
      Rarity.legendary: [Colors.amber[400]!, Colors.orange[600]!],
    };

    final rarityLabels = {
      Rarity.common: 'コモン',
      Rarity.rare: 'レア',
      Rarity.epic: 'エピック',
      Rarity.legendary: 'レジェンダリー',
    };

    final colors = rarityColors[item.rarity]!;

    return Container(
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
        border: Border.all(color: colors[0].withAlpha(128), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.network(
                    item.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.cyan[900],
                        child: const Icon(Icons.image, size: 48, color: Colors.white54),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rarityLabels[item.rarity]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.cyan[300],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy年MM月dd日').format(item.discoveredAt),
                  style: TextStyle(
                    color: Colors.cyan[400],
                    fontSize: 10,
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

