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

  // 3. 新規登録（メール、パスワード、ユーザー名）
  Future<UserProfile> signUpWithEmail({
    required String email, 
    required String password, 
    required String username
  }) async {
    // Firebase Authにユーザー作成
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    // Firestoreにプロフィール作成
    return await _createOrUpdateProfile(
      credential.user!.uid, 
      username,
      bio: '凍土に降り立った新たな探索者'
    );
  }

  // 4. 匿名ログイン（予備として残す場合）
  Future<UserProfile> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return await _createOrUpdateProfile(userCredential.user!.uid, '匿名ユーザー');
  }

  // 5. サインアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- 内部ヘルパーメソッド ---

  Future<UserProfile> _fetchProfileFromFirestore(String uid) async {
    final doc = await _db.collection(_userProfilesCollection).doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    // AuthにはいるがFirestoreにない場合（稀なケース）はプロフィール作成へ
    return await _createOrUpdateProfile(uid, 'ユーザー');
  }
  
  Future<UserProfile> _createOrUpdateProfile(String uid, String username, {String? avatar, String? bio}) async {
    final profileData = {
      'id': uid,
      'username': username,
      'avatar': avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=$uid', // デフォルトアイコン
      'bio': bio ?? '',
    };
    
    // merge: true にすることで既存データを消さずに更新
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