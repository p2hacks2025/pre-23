// lib/services/auth_service.dart (Firebase版)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/game.dart'; // ← これだと古いUserProfileを見に行くので削除
import '../models/user_profile.dart'; // ★★★ これを追加！

// UserProfileの初期値や、Firestoreへのアクセスを管理
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // ユーザープロファイルコレクションの参照
  static const String _userProfilesCollection = 'userProfiles';

  // 1. 現在の認証済みユーザーの取得
  Future<UserProfile> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _createGuestProfile(); 
    }
    
    final doc = await _db.collection(_userProfilesCollection).doc(user.uid).get();
    
    if (doc.exists) {
      // これで user_profile.dart の fromJson が呼ばれます
      return UserProfile.fromJson(doc.data()!);
    }
    
    return await _createOrUpdateProfile(user.uid, user.isAnonymous ? '匿名ユーザー' : 'ユーザー');
  }

  // 2. 匿名サインイン
  Future<UserProfile> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    final uid = userCredential.user!.uid;
    return await _createOrUpdateProfile(uid, '匿名ユーザー');
  }
  
  // 3. ユーザー名でのサインイン/プロフィール更新
  Future<UserProfile> signInWithUsername(String username) async {
    User? user = _auth.currentUser;
    if (user == null) {
      final userCredential = await _auth.signInAnonymously();
      user = userCredential.user;
    }
    
    final updatedProfile = await _createOrUpdateProfile(user!.uid, username);
    return updatedProfile;
  }

  // 4. サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // 5. Firestoreにプロフィールを作成/更新するヘルパー
  Future<UserProfile> _createOrUpdateProfile(String uid, String username, {String? avatar, String? bio}) async {
    final profileData = {
      'id': uid,
      'username': username,
      'avatar': avatar ?? '', 
      'bio': bio ?? '',
    };
    
    await _db.collection(_userProfilesCollection).doc(uid).set(profileData, SetOptions(merge: true));
    
    final doc = await _db.collection(_userProfilesCollection).doc(uid).get();
    return UserProfile.fromJson(doc.data()!);
  }

  // ゲストプロフィール
  UserProfile _createGuestProfile() {
    return UserProfile(id: 'guest', username: 'ゲスト', avatar: '', bio: '');
  }
}