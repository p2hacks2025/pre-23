// lib/models/memory.dart
// コメントクラスもここに同居させます

class Comment {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      author: json['author'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

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
  });

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
      photo: json['photo'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      authorId: json['authorId'],
      createdAt: DateTime.parse(json['createdAt']),
      discovered: json['discovered'] ?? false,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => Comment.fromJson(c))
          .toList(),
      starRating: json['starRating'] ?? 3,
    );
  }
}