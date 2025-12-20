import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http; 
import '../models/user_profile.dart';
import '../models/memory.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid(); 

  static const String _memoriesCollection = 'memories';
  static const String _userProfilesCollection = 'userProfiles';
  
  // --------------------------------------------------------------------------
  // ★ Web対応のためのヘルパーメソッド
  // --------------------------------------------------------------------------
  Future<Uint8List> getImageBytes(String path) async {
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      final response = await http.get(Uri.parse(path));
      return response.bodyBytes;
    }
    return await File(path).readAsBytes();
  }

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
  // 1. 記憶（Memory）の読み込み
  // --------------------------------------------------------------------------
  
  // 自分の投稿のみを監視
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

  // 自分以外の投稿を監視（発掘画面・ホームのコレクション用）
  Stream<List<Memory>> watchOthersMemories(String myUserId) {
    return _db
        .collection(_memoriesCollection)
        .snapshots() 
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Memory.fromJson(doc.data()))
          .where((memory) => memory.authorId != myUserId)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 全ての思い出を監視（ホーム画面で「自分の投稿」と「自分が発掘したもの」を混ぜて出す場合に便利）
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
  Future<void> createMemory({
    required String localPhotoPath,
    required String text,
    required String authorName,
    required String authorId,
    required int starRating,
  }) async {
    final String memoryId = _uuid.v4();
    String remotePhotoUrl = '';
    
    try {
      final storageRef = _storage.ref().child('memory_photos/$memoryId.jpg');
      
      if (kIsWeb) {
        final Uint8List bytes = await getImageBytes(localPhotoPath);
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final File file = File(localPhotoPath);
        await storageRef.putFile(file);
      }
      
      remotePhotoUrl = await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("画像アップロードエラー: $e");
      remotePhotoUrl = 'https://via.placeholder.com/400'; 
    }

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
      discoveredBy: null, // 初期値は誰も発掘していない
    );

    await _db.collection(_memoriesCollection).doc(memoryId).set(newMemory.toJson());
  }

  Future<void> deleteMemory(String memoryId) async {
    await _db.collection(_memoriesCollection).doc(memoryId).delete();
  }

  // ★ 修正：解凍時に「誰が発掘したか」を保存する
  Future<void> unlockMemory({
    required String memoryId,
    required String userId,
    String? comment,
    bool sendStampAutomatically = true, // 発掘時にキラキラを贈るフラグ
  }) async {
    final docRef = _db.collection(_memoriesCollection).doc(memoryId);
    final userRef = _db.collection(_userProfilesCollection).doc(userId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final String? authorId = data['authorId'];
      final int currentDigs = data['digCount'] ?? 0;
      final int currentStamps = data['stampsCount'] ?? 0;

      // 1. メモリドキュメントの更新
      Map<String, dynamic> memoryUpdates = {
        'digCount': currentDigs + 1,
        'discovered': true,
        'discoveredBy': userId,
      };

      if (sendStampAutomatically) {
        memoryUpdates['stampsCount'] = currentStamps + 1;
      }

      if (comment != null && comment.isNotEmpty) {
        // guestComments配列に追加
        memoryUpdates['guestComments'] = FieldValue.arrayUnion([comment]);
      }

      transaction.update(docRef, memoryUpdates);

      // 2. 発掘者（自分）の実績を更新
      transaction.update(userRef, {
        'totalDigs': FieldValue.increment(1),
        if (sendStampAutomatically) 'sendStampCount': FieldValue.increment(1),
if (comment != null && comment.trim().isNotEmpty) 'commentCount': FieldValue.increment(1),      });

      // 3. 投稿者（相手）の実績を更新
      if (authorId != null && authorId != userId) {
        final authorRef = _db.collection(_userProfilesCollection).doc(authorId);
        transaction.update(authorRef, {
          'beenDugCount': FieldValue.increment(1),
          if (sendStampAutomatically) 'receiveStampCount': FieldValue.increment(1),
        });
      }
    });
  }

  // 単体でスタンプを送る機能（既存機能維持）
  Future<void> sendStamp(String memoryId) async {
    final docRef = _db.collection(_memoriesCollection).doc(memoryId);
    await docRef.update({
      'stampsCount': FieldValue.increment(1),
    });
  }

  // 単体でコメントを送る機能（既存機能維持）
  Future<void> addComment(String memoryId, String comment) async {
    if (comment.isEmpty) return;
    final docRef = _db.collection(_memoriesCollection).doc(memoryId);
    await docRef.update({
      'guestComments': FieldValue.arrayUnion([comment]),
    });
  }
}