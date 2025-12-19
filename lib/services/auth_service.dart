// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static const String _userProfilesCollection = 'userProfiles';

  // 1. 現在のユーザー取得
  Future<UserProfile> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _createGuestProfile(); 
    }
    return await _fetchProfileFromFirestore(user.uid);
  }

  // 2. メールとパスワードでログイン
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    return await _fetchProfileFromFirestore(credential.user!.uid);
  }

  // 3. 新規登録
  Future<UserProfile> signUpWithEmail({
    required String email, 
    required String password, 
    required String username
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    return await _createOrUpdateProfile(
      credential.user!.uid, 
      username,
      bio: '凍土に降り立った新たな探索者'
    );
  }

  // 4. サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ★追加: パスワード変更
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Firebaseの仕様上、ログインから時間が経っているとエラー(requires-recent-login)になる場合があります
      await user.updatePassword(newPassword);
    } else {
      throw Exception('ユーザーがログインしていません');
    }
  }

  // --- 内部ヘルパーメソッド ---

  Future<UserProfile> _fetchProfileFromFirestore(String uid) async {
    final doc = await _db.collection(_userProfilesCollection).doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    return await _createOrUpdateProfile(uid, 'ユーザー');
  }
  
  Future<UserProfile> _createOrUpdateProfile(String uid, String username, {String? avatar, String? bio}) async {
    final profileData = {
      'id': uid,
      'username': username,
      'avatar': avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=$uid',
      'bio': bio ?? '',
    };
    
    await _db.collection(_userProfilesCollection).doc(uid).set(profileData, SetOptions(merge: true));
    
    return UserProfile(
      id: uid, 
      username: username, 
      avatar: profileData['avatar']!, 
      bio: profileData['bio']!
    );
  }

  UserProfile _createGuestProfile() {
    return UserProfile(id: 'guest', username: 'ゲスト', avatar: '', bio: '');
  }
}