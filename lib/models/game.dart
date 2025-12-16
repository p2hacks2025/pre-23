
enum ItemType {
  memory,
  gem,
  barrel,
  bottle,
  glass,
}

enum Rarity {
  common,
  rare,
  epic,
  legendary,
}

class Item {
  final String id;
  final ItemType type;
  final String name;
  final String description;
  final Rarity rarity;
  final String image;
  final DateTime discoveredAt;
  final String? memoryId;

  Item({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.rarity,
    required this.image,
    required this.discoveredAt,
    this.memoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'rarity': rarity.name,
      'image': image,
      'discoveredAt': discoveredAt.toIso8601String(),
      'memoryId': memoryId,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      type: ItemType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'],
      description: json['description'],
      rarity: Rarity.values.firstWhere((e) => e.name == json['rarity']),
      image: json['image'],
      discoveredAt: DateTime.parse(json['discoveredAt']),
      memoryId: json['memoryId'],
    );
  }
}

enum AchievementType {
  digCount,
  gemCount,
  barrelCount,
  bottleCount,
  glassCount,
  memoryCount,
  legendaryCount,
  collectionComplete,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requirement;
  final int progress;
  final bool completed;
  final bool isDaily;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.progress,
    required this.completed,
    required this.type,
    this.isDaily = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'requirement': requirement,
      'progress': progress,
      'completed': completed,
      'type': type.name,
      'isDaily': isDaily,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      requirement: json['requirement'],
      progress: json['progress'],
      completed: json['completed'],
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AchievementType.digCount,
      ),
      isDaily: json['isDaily'] == true,
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requirement,
    int? progress,
    bool? completed,
    AchievementType? type,
    bool? isDaily,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requirement: requirement ?? this.requirement,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      type: type ?? this.type,
      isDaily: isDaily ?? this.isDaily,
    );
  }
}

// ★★★ ここにあった UserProfile クラスは削除しました！ ★★★