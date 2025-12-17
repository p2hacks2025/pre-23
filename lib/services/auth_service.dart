// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
//import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  //final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String _userProfilesCollection = 'userProfiles';

  // ---------------------------------------------------
  // 1. 現在のユーザー取得 (匿名含む)
  // ---------------------------------------------------
  Future<UserProfile> getCurrentUser() async {
    final user = _auth.currentUser;

    // ログインしていなければ、裏側で「匿名ログイン」させる
    if (user == null) {
      try {
        await _auth.signInAnonymously();
        return _createGuestProfile();
      } catch (e) {
        debugPrint('Anonymous auth failed: $e');
        return _createGuestProfile();
      }
    }

    // ログイン済み (匿名 or 本登録)
    if (user.isAnonymous) {
      return _createGuestProfile();
    }

    try {
      final doc = await _db.collection(_userProfilesCollection).doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    
    // データが取れなかった場合
    return _createGuestProfile();
  }

  // ---------------------------------------------------
  // 2. ログイン処理 (メール または ユーザ名)
  // ---------------------------------------------------
  Future<UserProfile?> signIn({
    required String identifier, // email or username
    required String password,
  }) async {
    String email = identifier;

    try {
      // A. "@" が含まれていない場合 => 「ユーザ名」とみなしてメアドを検索
      if (!identifier.contains('@')) {
        final snapshot = await _db
            .collection(_userProfilesCollection)
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          // ユーザ名が存在しない場合、専用のエラーを投げる
          throw FirebaseAuthException(
            code: 'user-not-found', 
            message: 'User not found with this username'
          );
        }
        // メアドを取得 (Firestoreにemailフィールドが必要)
        email = snapshot.docs.first.data()['email'];
      }

      // B. Firebase Authでログイン実行
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // C. プロフィール情報を取得して返す
      final uid = credential.user!.uid;
      final doc = await _db.collection(_userProfilesCollection).doc(uid).get();
      return UserProfile.fromJson(doc.data()!);

    } on FirebaseAuthException {
      // ★修正: catch (e) を削除 (変数が未使用のため)
      // ここでエラーをキャッチせずそのまま上に投げて、UI側でハンドリングさせる
      rethrow; 
    } catch (e) {
      debugPrint('SignIn generic error: $e');
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  // ---------------------------------------------------
  // 3. 新規登録処理
  // ---------------------------------------------------
  Future<UserProfile?> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      // A. ユーザ名の重複チェック
      final check = await _db
          .collection(_userProfilesCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (check.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'The username is already taken.',
        );
      }

      // B. 匿名アカウントからのアップグレード判定
      // 現在匿名ログイン中なら linkWithCredential を使うのが理想ですが、
      // 簡単のため今回は「新規作成」フローにします。
      // (匿名データを引き継ぐ場合は linkWithCredential を使用します)

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // C. Firestoreにユーザー情報を保存
      final newProfileData = {
        'id': uid,
        'username': username,
        'email': email, // ★検索用に保存
        'createdAt': FieldValue.serverTimestamp(),
        // 必要に応じて初期値
        'totalDigs': 0,
        'achievements': [],
      };

      await _db.collection(_userProfilesCollection).doc(uid).set(newProfileData);

      return UserProfile(
        id: uid,
        username: username,
        avatar: '', // 必要なら追加
        bio: '',
      );

    } catch (e) {
      debugPrint('SignUp error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------
  // 4. サインアウト
  // ---------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
    // サインアウト後は再度「匿名」としてログインしておく（閲覧用）
    await _auth.signInAnonymously();
  }

  UserProfile _createGuestProfile() {
    return UserProfile(id: 'guest', username: 'ゲスト', avatar: '', bio: '');
  }
}