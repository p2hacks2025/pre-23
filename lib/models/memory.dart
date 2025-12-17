import 'comment.dart';

class Memory {
  final String id;
  final String photo;
  final String text;
  final String author;
  final String? authorId;
  final DateTime createdAt;
  final bool discovered;
  final List<Comment> comments;
  final int starRating; // 星の数（1〜5）

  Memory({
    required this.id,
    required this.photo,
    required this.text,
    required this.author,
    this.authorId,
    required this.createdAt,
    required this.discovered,
    required this.comments,
    this.starRating = 3, // デフォルト値
  });

  // ★ この行がエラーを解決します！
  // 星1なら10回、星5なら50回のタップが必要になる計算です
  int get requiredClicks => starRating * 10;

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
    );
  }
}