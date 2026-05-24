// lib/models/article_model.dart

class ArticleModel {
  final String id;          // url encode làm id
  final String title;
  final String content;
  final String summary;     // description từ NewsAPI
  final String imageUrl;
  final String category;
  final String author;
  final String sourceUrl;
  final DateTime publishedAt;
  int likesCount;
  int commentsCount;
  bool isLiked;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.imageUrl,
    required this.category,
    required this.author,
    required this.sourceUrl,
    required this.publishedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  // ── Parse từ NewsAPI response ──────────────────────────────────
  factory ArticleModel.fromNewsApi(Map<String, dynamic> json, String category) {
    final url = json['url'] ?? '';
    return ArticleModel(
      // Dùng url làm unique id
      id: Uri.encodeComponent(url),
      title: json['title'] ?? 'Không có tiêu đề',
      // NewsAPI free tier trả content bị cắt, dùng description + content
      content: _buildContent(json),
      summary: json['description'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      category: category,
      author: _parseAuthor(json),
      sourceUrl: url,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ── Parse từ Firestore (bài đã lưu local meta: likes, comments) ──
  factory ArticleModel.fromFirestore(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      summary: map['summary'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      author: map['author'] ?? '',
      sourceUrl: map['sourceUrl'] ?? '',
      publishedAt: map['publishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['publishedAt'])
          : DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id'          : id,
        'title'       : title,
        'content'     : content,
        'summary'     : summary,
        'imageUrl'    : imageUrl,
        'category'    : category,
        'author'      : author,
        'sourceUrl'   : sourceUrl,
        'publishedAt' : publishedAt.millisecondsSinceEpoch,
        'likesCount'  : likesCount,
        'commentsCount': commentsCount,
      };

  // ── SQLite local cache ─────────────────────────────────────────
  factory ArticleModel.fromSqlite(Map<String, dynamic> row) {
    return ArticleModel(
      id: row['id'],
      title: row['title'],
      content: row['content'],
      summary: row['summary'],
      imageUrl: row['imageUrl'],
      category: row['category'],
      author: row['author'],
      sourceUrl: row['sourceUrl'],
      publishedAt: DateTime.fromMillisecondsSinceEpoch(row['publishedAt']),
    );
  }

  Map<String, dynamic> toSqlite() => {
        'id'          : id,
        'title'       : title,
        'content'     : content,
        'summary'     : summary,
        'imageUrl'    : imageUrl,
        'category'    : category,
        'author'      : author,
        'sourceUrl'   : sourceUrl,
        'publishedAt' : publishedAt.millisecondsSinceEpoch,
      };

  // ── Helpers ────────────────────────────────────────────────────
  static String _buildContent(Map<String, dynamic> json) {
    final desc = json['description'] ?? '';
    final raw  = json['content'] ?? '';
    // NewsAPI free cắt ở [+N chars], bỏ phần đó
    final cleaned = raw.replaceAll(RegExp(r'\[\+\d+ chars\]'), '').trim();
    if (cleaned.isEmpty) return desc;
    if (desc.isEmpty) return cleaned;
    return '$desc\n\n$cleaned';
  }

  static String _parseAuthor(Map<String, dynamic> json) {
    final author = json['author'];
    final source = json['source']?['name'] ?? '';
    if (author != null && author.toString().isNotEmpty) {
      return author.toString();
    }
    return source.isNotEmpty ? source : 'Biên tập viên';
  }
}
