//lib/models/memory.dart

import 'comment.dart';

class Memory {
  final String id;
  final String photo;
  final String text;
  final String author;
  final String? authorId;
  final DateTime createdAt;
  bool discovered;
  final List<Comment> comments;
  final int starRating;
  
  // ★ 修正：スタンプは✨1種類のみに統合
  final List<String> guestComments; // 追加
  int stampsCount;
  // ★ 追加：累計発掘回数
  int digCount;

  Memory({
    required this.id,
    required this.photo,
    required this.text,
    required this.author,
    this.authorId,
    required this.createdAt,
    required this.discovered,
    required this.comments,
    this.starRating = 3,
    required this.guestComments, // 追加
    this.stampsCount = 0,
    this.digCount = 0,
  });

  // ★ 重要：スタンプ数の合計で発掘に必要なタップ数が増えるロジック
  // 基本値 (星×5) + スタンプされた数
  int get requiredClicks => (starRating * 5) + stampsCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo': photo,
      'text': text,
      'author': author,
      'authorId': authorId,
      'createdAt': createdAt.toIso8601String(),
      'discovered': discovered,
      'comments': comments.map((c) => c.toJson()).toList(),
      'starRating': starRating,
      'stampsCount': stampsCount,
      'digCount': digCount,
    };
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'],
      photo: json['photo'],
      text: json['text'],
      author: json['author'],
      authorId: json['authorId'],
      createdAt: DateTime.parse(json['createdAt']),
      discovered: json['discovered'] ?? false,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => Comment.fromJson(c))
              .toList() ?? [],
      starRating: json['starRating'] ?? 3,
      guestComments: (json['guestComments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stampsCount: json['stampsCount'] ?? 0,
      digCount: json['digCount'] ?? 0,
    );
  }
}