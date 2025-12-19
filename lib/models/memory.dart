import 'package:cloud_firestore/cloud_firestore.dart'; // ★必須：Timestamp型を扱うため
import 'comment.dart';

class Memory {
  final String id;
  final String photo;
  final String text;
  final String author;
  final String? authorId;
  final DateTime createdAt;
  final bool discovered; // ★ final を追加して不変にする
  final List<Comment> comments;
  final int starRating;
  final List<String> guestComments;
  final int stampsCount; // ★ final を追加
  final int digCount;    // ★ final を追加
  final String? discoveredBy;

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
    required this.guestComments,
    this.stampsCount = 0,
    this.digCount = 0,
    this.discoveredBy,
  });

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
      'guestComments': guestComments,
      'discoveredBy': discoveredBy,
    };
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    // --- createdAt の安全な解析ロジックを追加 ---
    DateTime parsedDate;
    var rawDate = json['createdAt'];

    if (rawDate is Timestamp) {
      // Firestoreから直接届く「Timestamp型」の場合
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      // JSON文字列（ISO8601）として届く場合
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      // データが欠落している等の場合
      parsedDate = DateTime.now();
    }
    // ---------------------------------------

    return Memory(
      id: json['id'] ?? '',
      photo: json['photo'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      authorId: json['authorId'],
      createdAt: parsedDate, // 解析した日時を使用
      discovered: json['discovered'] ?? false,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => Comment.fromJson(c))
              .toList() ?? [],
      starRating: json['starRating'] ?? 3,
      guestComments: (json['guestComments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      stampsCount: json['stampsCount'] ?? 0,
      digCount: json['digCount'] ?? 0,
      discoveredBy: json['discoveredBy'],
    );
  }
}