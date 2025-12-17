// lib/services/api_service.dart

import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // debugPrint用
// import 'package:firebase_auth/firebase_auth.dart'; // 削除 (_auth未使用のため)
import '../models/user_profile.dart';
import '../models/memory.dart';
import '../models/game.dart';


class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance; // ★ 削除 (未使用警告対応)
  final Uuid _uuid = const Uuid(); 

  // UUIDジェネレータの公開ゲッター
  Uuid get uuidGenerator => _uuid; 

  // Firestoreコレクション名
  static const String _memoriesCollection = 'memories';
  static const String _userProfilesCollection = 'userProfiles';
  // static const String _itemsCollection = 'items'; // ★ 削除 (未使用警告対応)
  
  // --------------------------------------------------------------------------
  // ユーザー認証・プロフィール (AuthServiceと連携)
  // --------------------------------------------------------------------------

  Future<UserProfile> fetchUserProfile(String userId) async {
    final doc = await _db.collection(_userProfilesCollection).doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    throw Exception('UserProfile not found for ID: $userId'); 
  }
  
  // --------------------------------------------------------------------------
  // 記憶 (Memory) 関連の操作
  // --------------------------------------------------------------------------

// 1. 記憶の投稿 (封印)
  Future<Memory?> postMemory({
    required String localPhotoPath, 
    required String text, 
    required String author, 
    required String authorId,
    int starRating = 3, // ★ この行を追加してください！
  }) async {
    final memoryId = _uuid.v4();
    
    try {
      final storageRef = _storage.ref().child('memories/$authorId/$memoryId.jpg');
      
      final file = File(localPhotoPath);
      if (!file.existsSync()) {
        debugPrint('Error: Local file not found at $localPhotoPath');
        return null;
      }

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      
      final memory = Memory(
        id: memoryId,
        photo: downloadUrl, 
        text: text,
        author: author,
        authorId: authorId,
        createdAt: DateTime.now(),
        discovered: false, 
        comments: [],
        starRating: starRating, // ★ ここにも追加してください！
      );

      await _db.collection(_memoriesCollection).doc(memoryId).set(memory.toJson());
      return memory;

    } catch (e) {
      debugPrint('🔥 Error posting memory: $e');
      return null;
    }
  }
  // 2. 自分の投稿した記憶のフェッチ (ホーム画面用)
  Future<List<Memory>> fetchUserMemories(String userId) async {
    final snapshot = await _db.collection(_memoriesCollection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Memory.fromJson(doc.data())).toList();
  }
  
  // 3. 発掘ゲーム用の未発見の記憶のフェッチ
  Future<List<Memory>> fetchUndiscoveredMemories(String userId) async {
    final snapshot = await _db.collection(_memoriesCollection)
        .where('discovered', isEqualTo: false)
        .where('authorId', isNotEqualTo: userId) // 自分の投稿は除外
        .limit(10) 
        .get();

    return snapshot.docs.map((doc) => Memory.fromJson(doc.data())).toList();
  }

  // 4. ユーザーが発掘した記憶のフェッチ (コレクション画面用)
  Future<List<Memory>> fetchUserDiscoveredMemories(String userId) async {
    final discoveredRefs = await _db.collection(_userProfilesCollection).doc(userId)
        .collection('discoveredMemories')
        .where('type', isEqualTo: 'memory')
        .get();

    if (discoveredRefs.docs.isEmpty) {
      return [];
    }
    
    final memoryIds = discoveredRefs.docs.map((doc) => doc.id).toList();
    
    if (memoryIds.isEmpty) return [];

    final memoryDocs = await _db.collection(_memoriesCollection)
        .where(FieldPath.documentId, whereIn: memoryIds.take(10)) 
        .get();

    return memoryDocs.docs.map((doc) => Memory.fromJson(doc.data())).toList();
  }


  // 5. 発掘処理 (記憶) 
  Future<void> discoverMemory(Memory memory, String discovererId) async {
    await _db.collection(_memoriesCollection).doc(memory.id).update({
      'discovered': true,
    });
    
    await _db.collection(_userProfilesCollection).doc(discovererId)
        .collection('discoveredMemories').doc(memory.id).set({
      'memoryId': memory.id,
      'discoveredAt': FieldValue.serverTimestamp(),
      'type': 'memory',
    });
    
    await _db.collection(_userProfilesCollection).doc(discovererId).update({
      'totalDigs': FieldValue.increment(1),
    });
  }

  // --------------------------------------------------------------------------
  // アイテム (Item) 関連の操作
  // --------------------------------------------------------------------------

  // 6. アイテムの発掘処理
  Future<void> discoverItem(Item item, String discovererId) async {
    await _db.collection(_userProfilesCollection).doc(discovererId)
        .collection('items').doc(item.id).set(item.toJson());
        
    await _db.collection(_userProfilesCollection).doc(discovererId).update({
      'totalDigs': FieldValue.increment(1),
    });
  }
  
  // 7. ユーザーのコレクションアイテムのフェッチ
  Future<List<Item>> fetchUserItems(String userId) async {
     final snapshot = await _db.collection(_userProfilesCollection).doc(userId)
        .collection('items')
        .get();

    return snapshot.docs.map((doc) => Item.fromJson(doc.data())).toList();
  }

  // --------------------------------------------------------------------------
  // コメント機能
  // --------------------------------------------------------------------------

  // 8. コメントの追加
  Future<void> addComment(String memoryId, Comment comment) async {
    await _db.collection(_memoriesCollection).doc(memoryId)
        .collection('comments').doc(comment.id).set(comment.toJson());
  }

  // 9. 記憶に紐づくコメントのフェッチ
  Future<List<Comment>> fetchCommentsForMemory(String memoryId) async {
     final snapshot = await _db.collection(_memoriesCollection).doc(memoryId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
  }
  
  // --------------------------------------------------------------------------
  // 実績 (Achievement) 関連の操作
  // --------------------------------------------------------------------------

  // 10. 実績と累積発掘回数のフェッチ
  Future<Map<String, dynamic>> fetchUserAchievementsAndDigs(String userId) async {
    final profileDoc = await _db.collection(_userProfilesCollection).doc(userId).get();
    
    if (profileDoc.exists) {
      final data = profileDoc.data()!;
      
      final int totalDigs = data['totalDigs'] as int? ?? 0;
      
      final List<Achievement> achievements = (data['achievements'] as List<dynamic>? ?? [])
          .map((json) => Achievement.fromJson(json))
          .toList();
          
      return {
        'achievements': achievements,
        'totalDigs': totalDigs,
      };
    }
    
    return {
      'achievements': [], 
      'totalDigs': 0,
    };
  }

  // 11. 最後に発掘した日時の取得
  Future<DateTime?> fetchLastDigDate(String userId) async {
    final dailyDataDoc = await _db.collection(_userProfilesCollection).doc(userId)
        .collection('dailyStats').doc('current').get();

    if (dailyDataDoc.exists) {
        final timestamp = dailyDataDoc.data()?['lastDigDate'] as Timestamp?;
        return timestamp?.toDate();
    }
    return null;
  }

  // lib/services/api_service.dart 内に追加

Future<void> deleteMemory(String memoryId) async {
  try {
    // Firebase Firestoreから削除する場合
    await _db.collection('memories').doc(memoryId).delete();
    debugPrint('Memory $memoryId deleted successfully');
  } catch (e) {
    debugPrint('Error deleting memory: $e');
    // 通信エラーなどで削除できない場合も、
    // 必要に応じてリバース処理やエラー通知を検討してください。
  }
}
}