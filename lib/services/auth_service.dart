import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // シングルトン化（アプリ内で1つのインスタンスを共有）
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 現在のユーザーを保持
  UserProfile? _currentUser;

  // ゲストユーザー定義
  final UserProfile _guestUser = UserProfile(
    id: 'guest',
    username: 'Guest',
    avatar: '',
    bio: '旅の途中',
  );

  // 現在のユーザーを取得（未ログインならゲストを返す）
  Future<UserProfile> getCurrentUser() async {
    if (_currentUser != null) return _currentUser!;
    // ★本来はここでSharedPreferenceなどを確認して自動ログイン処理を入れる
    return _guestUser; 
  }

  bool get isGuest => _currentUser?.id == 'guest' || _currentUser == null;

  // サインイン（ユーザー名 + パスコード）
  Future<bool> signIn(String username, String passcode) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .where('passcode', isEqualTo: passcode) // ★本番ではハッシュ化推奨
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        _currentUser = UserProfile(
          id: doc.id,
          username: data['username'] ?? '',
          avatar: data['avatar'] ?? '',
          bio: data['bio'] ?? '',
        );
        return true; // 成功
      } else {
        return false; // ユーザーが見つからないかパスワード違い
      }
    } catch (e) {
      debugPrint('SignIn Error: $e');
      return false;
    }
  }

  // 新規登録
  Future<bool> signUp(String username, String passcode) async {
    try {
      // 重複チェック
      final check = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      if (check.docs.isNotEmpty) {
        return false; // 既に存在するユーザー名
      }

      // ユーザー作成
      final docRef = _firestore.collection('users').doc(); // 自動ID
      await docRef.set({
        'username': username,
        'passcode': passcode,
        'avatar': '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // そのままログイン状態にする
      _currentUser = UserProfile(
        id: docRef.id,
        username: username,
        avatar: '',
        bio: '',
      );
      return true;
    } catch (e) {
      debugPrint('SignUp Error: $e');
      return false;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    _currentUser = null;
  }
}