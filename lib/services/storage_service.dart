import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memory.dart';
import '../models/game.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _memoriesKey = 'memories';
  static const String _discoveredMemoriesKey = 'discoveredMemories';
  static const String _itemsKey = 'items';
  static const String _achievementsKey = 'achievements';
  static const String _totalDigsKey = 'totalDigs';
  static const String _userProfileKey = 'userProfile';
  static const String _usersKey = 'users';
  static const String _dailyDigDataKey = 'dailyDigData';

  // Memories
  Future<List<Memory>> getMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = prefs.getString(_memoriesKey);
    if (memoriesJson == null) {
      return _getSampleMemories();
    }
    final List<dynamic> decoded = json.decode(memoriesJson);
    return decoded.map((m) => Memory.fromJson(m)).toList();
  }

  Future<void> saveMemories(List<Memory> memories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(memories.map((m) => m.toJson()).toList());
    await prefs.setString(_memoriesKey, jsonString);
  }

  // Discovered Memories
  Future<List<Memory>> getDiscoveredMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = prefs.getString(_discoveredMemoriesKey);
    if (memoriesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(memoriesJson);
    return decoded.map((m) => Memory.fromJson(m)).toList();
  }

  Future<void> saveDiscoveredMemories(List<Memory> memories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(memories.map((m) => m.toJson()).toList());
    await prefs.setString(_discoveredMemoriesKey, jsonString);
  }

  // Items
  Future<List<Item>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_itemsKey);
    if (itemsJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(itemsJson);
    return decoded.map((i) => Item.fromJson(i)).toList();
  }

  Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_itemsKey, jsonString);
  }

  // Achievements
  Future<List<Achievement>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString(_achievementsKey);
    if (achievementsJson == null) {
      return _getInitialAchievements();
    }
    final List<dynamic> decoded = json.decode(achievementsJson);
    final List<Achievement> loaded = decoded.map((a) => Achievement.fromJson(a)).toList();

    // Migrate: remove barrel/glass achievements and ensure single bottle collector with requirement 50
    bool changed = false;
    // Filter out barrel and glass achievements
    final filtered = loaded.where((a) => a.type != AchievementType.barrelCount && a.type != AchievementType.glassCount).toList();

    // Find bottle achievement
    final bottleIndex = filtered.indexWhere((a) => a.type == AchievementType.bottleCount);
    if (bottleIndex != -1) {
      final bottle = filtered[bottleIndex];
      if (bottle.requirement < 50 || bottle.id != 'bottle_50') {
        filtered[bottleIndex] = bottle.copyWith(
          id: 'bottle_50',
          title: 'ビール瓶コレクター',
          description: 'ビール瓶を50本集める',
          requirement: 50,
        );
        changed = true;
      }
    } else {
      // no bottle achievement present — add one
      filtered.add(
        Achievement(
          id: 'bottle_50',
          title: 'ビール瓶コレクター',
          description: 'ビール瓶を50本集める',
          icon: '🍾',
          requirement: 50,
          progress: 0,
          completed: false,
          type: AchievementType.bottleCount,
        ),
      );
      changed = true;
    }

    if (changed) {
      await saveAchievements(filtered);
    }

    return filtered;
  }

  Future<void> saveAchievements(List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(achievements.map((a) => a.toJson()).toList());
    await prefs.setString(_achievementsKey, jsonString);
  }

  // Total Digs
  Future<int> getTotalDigs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalDigsKey) ?? 0;
  }

  Future<void> saveTotalDigs(int totalDigs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalDigsKey, totalDigs);
  }

  // User Profile
  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    if (profileJson == null) {
      return UserProfile(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        username: 'ゲスト',
        avatar: '',
        bio: '',
      );
    }
    return UserProfile.fromJson(json.decode(profileJson));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(profile.toJson());
    await prefs.setString(_userProfileKey, jsonString);
    // ensure the profile is present in the users list
    await saveOrUpdateUser(profile);
  }

  // Users list (for multi-user resolving)
  Future<List<UserProfile>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return [];
    final List<dynamic> decoded = json.decode(usersJson);
    return decoded.map((u) => UserProfile.fromJson(u)).toList();
  }

  Future<void> saveUsers(List<UserProfile> users) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, jsonString);
  }

  Future<void> saveOrUpdateUser(UserProfile profile) async {
    final users = await getUsers();
    final idx = users.indexWhere((u) => u.id == profile.id);
    if (idx != -1) {
      users[idx] = profile;
    } else {
      users.add(profile);
    }
    await saveUsers(users);
  }

  // Daily Digs
  Future<Map<String, dynamic>> getDailyDigData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_dailyDigDataKey);
    if (dataJson == null) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      return {'date': today, 'remaining': 3, 'used': 0};
    }
    final Map<String, dynamic> decoded = json.decode(dataJson);
    decoded['used'] = decoded['used'] ?? 0;
    return decoded;
  }

  Future<void> saveDailyDigData(String date, int remaining, [int used = 0]) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {'date': date, 'remaining': remaining, 'used': used};
    await prefs.setString(_dailyDigDataKey, json.encode(data));
  }

  // Sample data
  List<Memory> _getSampleMemories() {
    return [
      Memory(
        id: '1',
        photo: 'https://images.unsplash.com/photo-1491002052546-bf38f186af56?w=800',
        text: '凍てつく山頂で見た氷の結晶',
        author: '氷の旅人',
        createdAt: DateTime(2024, 1, 15),
        discovered: false,
        comments: [],
      ),
      Memory(
        id: '2',
        photo: 'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?w=800',
        text: 'オーロラが輝く夜の記憶',
        author: '星の観測者',
        createdAt: DateTime(2024, 2, 20),
        discovered: false,
        comments: [],
      ),
      Memory(
        id: '3',
        photo: 'https://images.unsplash.com/photo-1418985991508-e47386d96a71?w=800',
        text: '永久凍土に眠る古代の遺跡',
        author: '遺跡探検家',
        createdAt: DateTime(2024, 3, 10),
        discovered: false,
        comments: [],
      ),
      Memory(
        id: '4',
        photo: 'https://images.unsplash.com/photo-1457269449834-928af64c684d?w=800',
        text: '雪原に咲く幻の氷花',
        author: '植物学者',
        createdAt: DateTime(2024, 4, 5),
        discovered: false,
        comments: [],
      ),
      Memory(
        id: '5',
        photo: 'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=800',
        text: '凍った湖の奥底に見えた光',
        author: '湖の守護者',
        createdAt: DateTime(2024, 5, 12),
        discovered: false,
        comments: [],
      ),
    ];
  }

  List<Achievement> _getInitialAchievements() {
    return [
      Achievement(
        id: 'dig_10',
        title: '初心者発掘家',
        description: '1日で10回発掘する (デイリー)',
        icon: '⛏️',
        requirement: 10,
        progress: 0,
        completed: false,
        type: AchievementType.digCount,
        isDaily: true,
      ),
      Achievement(
        id: 'dig_50',
        title: '熟練発掘家',
        description: '1日で50回発掘する (デイリー)',
        icon: '💎',
        requirement: 50,
        progress: 0,
        completed: false,
        type: AchievementType.digCount,
        isDaily: true,
      ),
      Achievement(
        id: 'gem_5',
        title: '宝石コレクター',
        description: '1日で宝石を5つ集める (デイリー)',
        icon: '💍',
        requirement: 5,
        progress: 0,
        completed: false,
        type: AchievementType.gemCount,
        isDaily: true,
      ),
      Achievement(
        id: 'bottle_50',
        title: 'ビール瓶コレクター',
        description: '1日でビール瓶を50本集める (デイリー)',
        icon: '🍾',
        requirement: 50,
        progress: 0,
        completed: false,
        type: AchievementType.bottleCount,
        isDaily: true,
      ),
      Achievement(
        id: 'memory_10',
        title: '記憶の守護者',
        description: '累積で記憶を10個発掘する',
        icon: '📸',
        requirement: 10,
        progress: 0,
        completed: false,
        type: AchievementType.memoryCount,
        isDaily: false,
      ),
      Achievement(
        id: 'legendary_1',
        title: '伝説の発掘家',
        description: '累積でレジェンダリーアイテムを入手する',
        icon: '⭐',
        requirement: 1,
        progress: 0,
        completed: false,
        type: AchievementType.legendaryCount,
        isDaily: false,
      ),
    ];
  }
}

