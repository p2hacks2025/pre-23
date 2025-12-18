//lib/models/comment.dart

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

