// lib/models/comment_model.dart

class CommentModel {
  final String id;
  final String userId;
  final String articleId;
  final String content;
  final String username;
  final String? userAvatar;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.articleId,
    required this.content,
    required this.username,
    this.userAvatar,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['userId'] ?? '',
      articleId: map['articleId'] ?? '',
      content: map['content'] ?? '',
      username: map['username'] ?? 'Ẩn danh',
      userAvatar: map['userAvatar'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId'     : userId,
    'articleId'  : articleId,
    'content'    : content,
    'username'   : username,
    'userAvatar' : userAvatar,
    'createdAt'  : createdAt.millisecondsSinceEpoch,
  };
}