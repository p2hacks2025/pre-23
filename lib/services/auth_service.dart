import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static const String _userProfilesCollection = 'userProfiles';

  // ★追加: ログイン状態の変化をリアルタイムで流す (機能を減らさず追加)
  // これにより、ログイン・ログアウトした瞬間に他の画面がそれを検知できます
  Stream<UserProfile?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      // ユーザーが切り替わったらFirestoreから最新のプロフィールを取得
      return await _fetchProfileFromFirestore(user.uid);
    });
  }

  // 1. 現在のユーザー取得 (既存)
  Future<UserProfile> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _createGuestProfile(); 
    }
    return await _fetchProfileFromFirestore(user.uid);
  }

  // 2. メールとパスワードでログイン (既存)
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    return await _fetchProfileFromFirestore(credential.user!.uid);
  }

  // 3. 新規登録 (既存)
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

  // 4. サインアウト (既存)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 5. パスワード変更 (既存)
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('ユーザーがログインしていません');
    }
  }

  // --- 内部ヘルパーメソッド (既存) ---

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