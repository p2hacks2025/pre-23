// lib/services/api_service.dart

import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/memory.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
//import '../models/game.dart';
// import '../models/comment.dart'; 

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid(); 

  // コレクション名
  static const String _memoriesCollection = 'memories';
  static const String _userProfilesCollection = 'userProfiles';
  
  // --------------------------------------------------------------------------
  // ユーザー認証・プロフィール関連
  // --------------------------------------------------------------------------

  Future<UserProfile> fetchUserProfile(String userId) async {
    final doc = await _db.collection(_userProfilesCollection).doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    return UserProfile(id: userId, username: 'Unknown', avatar: '', bio: '');
  }

  // --------------------------------------------------------------------------
  // 1. 記憶（Memory）の読み込み - リアルタイム監視 (Stream)
  // --------------------------------------------------------------------------

  // 【自分】の記憶のみを監視するStream (home_screenで使用)
  Stream<List<Memory>> watchMyMemories(String userId) {
    return _db
        .collection(_memoriesCollection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Memory.fromJson(doc.data())).toList();
    });
  }

  // 【他人】の記憶（未発掘のものなど）を監視するStream (home_screenで使用)
  Stream<List<Memory>> watchOthersMemories(String myUserId) {
    return _db
        .collection(_memoriesCollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Memory.fromJson(doc.data()))
          .where((memory) => memory.authorId != myUserId) // 自分以外のもの
          .toList();
    });
  }

  // ★ 追加: 全ての記憶を監視するStream (HomeScreenでのフィルタリング用)
  Stream<List<Memory>> watchAllMemories() {
    return _db
        .collection(_memoriesCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Memory.fromJson(doc.data())).toList();
    });
  }

  // --------------------------------------------------------------------------
  // 2. 記憶（Memory）の操作
  // --------------------------------------------------------------------------

  // 新しい記憶を投稿 (home_screenで使用)
  Future<void> createMemory({
    required String localPhotoPath,
    required String text,
    required String authorName,
    required String authorId,
    required int starRating,
  }) async {
    final String memoryId = _uuid.v4();
    
    // 1. 画像をStorageにアップロード
    String remotePhotoUrl = '';
    try {
      final File file = File(localPhotoPath);
      final storageRef = _storage.ref().child('memory_photos/$memoryId.jpg');
      await storageRef.putFile(file);
      remotePhotoUrl = await storageRef.getDownloadURL();
    } catch (e) {


      debugPrint("画像アップロードエラー: $e");
      // エラー時はダミーURLかローカルパスを入れるなどの救済措置

      remotePhotoUrl = 'https://via.placeholder.com/400'; 
    }

    // 2. Firestoreに保存
    final newMemory = Memory(
      id: memoryId,
      photo: remotePhotoUrl,
      text: text,
      author: authorName,
      authorId: authorId,
      createdAt: DateTime.now(),
      discovered: false,
      comments: [],
      guestComments: [],
      starRating: starRating,
      stampsCount: 0,
      digCount: 0,
    );

    await _db.collection(_memoriesCollection).doc(memoryId).set(newMemory.toJson());
  }

  // 記憶を削除 (home_screenで使用)
  Future<void> deleteMemory(String memoryId) async {
    await _db.collection(_memoriesCollection).doc(memoryId).delete();
  }

  // 記憶を発掘完了にする (digging_game_screen経由で使用)
  // ★ 修正: 二重定義を解消し、discoveredフラグ更新を1つのメソッドに集約
  Future<void> unlockMemory(String memoryId, String userId) async {
    final docRef = _db.collection(_memoriesCollection).doc(memoryId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentDigs = snapshot.data()?['digCount'] ?? 0;
      
      // メモリ自体の更新
      transaction.update(docRef, {
        'digCount': currentDigs + 1,
        'discovered': true, // これによりDiscovery画面から消え、Home画面に現れる
      });
      
      // 発掘者の実績（累計発掘数）をカウントアップ
      final userRef = _db.collection(_userProfilesCollection).doc(userId);
      transaction.update(userRef, {
        'totalDigs': FieldValue.increment(1),
      });
    });
  }

  // スタンプ（リアクション）を送る (digging_game_screen経由で使用)
  Future<void> sendStamp(String memoryId) async {
    final docRef = _db.collection(_memoriesCollection).doc(memoryId);
    await docRef.update({
      'stampsCount': FieldValue.increment(1),
    });
  }

  // --------------------------------------------------------------------------
  // 3. 実績・統計データの取得
  // --------------------------------------------------------------------------
  
  Future<Map<String, dynamic>> fetchUserAchievementsAndDigs(String userId) async {
    final profileDoc = await _db.collection(_userProfilesCollection).doc(userId).get();
    
    if (profileDoc.exists) {
      final data = profileDoc.data()!;
      return {
        'totalDigs': data['totalDigs'] ?? 0,
      };
    }
    return {'totalDigs': 0};
  }
}