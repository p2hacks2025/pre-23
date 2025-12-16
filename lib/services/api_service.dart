import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/memory.dart';
import '../models/comment.dart';
import '../models/game.dart'; // Item定義など
import 'package:flutter/foundation.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid uuidGenerator = const Uuid();

  // ★ 未発見（他人の投稿）の記憶を取得
  Future<List<Memory>> fetchUndiscoveredMemories(String userId) async {
    try {
      // 最新20件を取得
      final snapshot = await _firestore
          .collection('memories')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      List<Memory> memories = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // 自分の投稿は発掘対象外
        if (data['authorId'] == userId) continue;

        // ★ ここを修正: Memoryモデルの定義に合わせて変換
        memories.add(Memory(
          id: doc.id,
          author: data['authorName'] ?? 'Unknown',
          authorId: data['authorId'], // nullable
          text: data['text'] ?? '',
          
          // モデルの 'photo' に Firestoreの 'imageUrl' を渡す
          photo: data['imageUrl'] ?? '', 
          
          // モデルの 'createdAt' に変換して渡す
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          
          // モデルの 'discovered' (bool)
          // ここでは「未発見リスト」を取得するロジックなので、
          // アプリ上の表示としては false (未発掘) 扱いにするか、
          // Firestoreの 'discoveredBy' 配列を見て判定するかになります。
          // 一旦 false (これから掘るもの) として設定します。
          discovered: false, 

          // モデルの 'comments' (List<Comment>)
          // Firestoreのサブコレクションを取得するのは非同期処理が必要なため、
          // ここでは一旦空リストを渡します。
          comments: [], 
        ));
      }
      return memories;
    } catch (e) {
      debugPrint('Fetch Error: $e');
      return [];
    }
  }

  // 記憶の投稿
  Future<void> postMemory({
    required String localPhotoPath,
    required String text,
    required String author,
    required String authorId,
  }) async {
    // ★画像アップロード処理（Firebase Storage）が必要ですが、
    // ここではパスをそのまま保存、またはBase64化などを想定
    
    await _firestore.collection('memories').add({
      'authorName': author,
      'authorId': authorId,
      'text': text,
      'imageUrl': localPhotoPath, // Firestore上では imageUrl というキーで保存
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [], // 将来的に使うためにDBには入れておく
      'discoveredBy': [],
    });
  }

  // アイテム発見（Firestoreに保存）
  Future<void> discoverItem(Item item, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('collection')
        .doc(item.id)
        .set({
          'name': item.name,
          'discoveredAt': FieldValue.serverTimestamp(),
        });
  }
  
  // 記憶を発見済みにする
  Future<void> discoverMemory(Memory memory, String userId) async {
     await _firestore.collection('memories').doc(memory.id).update({
       'discoveredBy': FieldValue.arrayUnion([userId])
     });
  }

  // ★ コメント追加（ログインユーザーのみ実行される前提）
  Future<void> addComment(String memoryId, Comment comment) async {
    // サブコレクションとして保存
    await _firestore
        .collection('memories')
        .doc(memoryId)
        .collection('comments')
        .add({
          'author': comment.author,
          'text': comment.text,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
  
  // 他のメソッド（fetchUserMemoriesなど）
  Future<List<Memory>> fetchUserMemories(String userId) async {
    // 必要に応じて実装。ここでは空リストを返す。
    return []; 
  }
  
  Future<List<Item>> fetchUserItems(String userId) async { 
    return []; 
  }
  
  Future<Map<String, dynamic>> fetchUserAchievementsAndDigs(String userId) async {
    return {'achievements': [], 'totalDigs': 0};
  }
  
  Future<DateTime?> fetchLastDigDate(String userId) async { 
    return null; 
  }
}