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

  Memory({
    required this.id,
    required this.photo,
    required this.text,
    required this.author,
    this.authorId,
    required this.createdAt,
    required this.discovered,
    required this.comments,
  });

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
              .toList() ??
          [],
    );
  }

  Memory copyWith({
    String? id,
    String? photo,
    String? text,
    String? author,
    String? authorId,
    DateTime? createdAt,
    bool? discovered,
    List<Comment>? comments,
  }) {
    return Memory(
      id: id ?? this.id,
      photo: photo ?? this.photo,
      text: text ?? this.text,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      discovered: discovered ?? this.discovered,
      comments: comments ?? this.comments,
    );
  }
}

