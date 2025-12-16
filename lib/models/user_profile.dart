// lib/models/user_profile.dart
//import 'package:flutter/foundation.dart'; // 必要に応じて

class UserProfile {
  final String id;
  final String username;
  final String avatar; // アバター画像のURLなど
  final String bio; // 自己紹介文

  UserProfile({
    required this.id,
    required this.username,
    required this.avatar,
    required this.bio,
  });

  // 複製（コピー）用のメソッド
  UserProfile copyWith({
    String? id,
    String? username,
    String? avatar,
    String? bio,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
    );
  }

  // Firestore/APIからの読み込み用のファクトリコンストラクタ
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'guest',
      username: json['username'] as String? ?? 'ゲスト',
      avatar: json['avatar'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
    );
  }

  // Firestore/APIへの書き込み用のメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'bio': bio,
    };
  }
}