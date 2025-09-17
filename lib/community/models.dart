// lib/models.dart

class Post {
  final String id;
  final String username;
  final String userAvatarUrl;
  final String title;
  final String content;
  final int upvotes;
  final int commentCount;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.username,
    required this.userAvatarUrl,
    required this.title,
    required this.content,
    required this.upvotes,
    required this.commentCount,
    required this.timestamp,
  });

  // Factory constructor to create a Post from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      username: json['username'],
      userAvatarUrl: json['userAvatarUrl'],
      title: json['title'],
      content: json['content'],
      upvotes: json['upvotes'],
      commentCount: json['commentCount'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Comment {
  final String id;
  final String username;
  final String userAvatarUrl;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.username,
    required this.userAvatarUrl,
    required this.text,
    required this.timestamp,
  });

  // Factory constructor to create a Comment from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      username: json['username'],
      userAvatarUrl: json['userAvatarUrl'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}