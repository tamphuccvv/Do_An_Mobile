// lib/services/bookmark_service.dart
// Tính năng 8: Bộ sưu tập (Bookmarks / Folders)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';

class BookmarkFolder {
  final String id;
  final String name;
  final String userId;
  final DateTime createdAt;
  int articleCount;

  BookmarkFolder({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    this.articleCount = 0,
  });

  factory BookmarkFolder.fromMap(Map<String, dynamic> map, String id) =>
      BookmarkFolder(
        id: id,
        name: map['name'] ?? '',
        userId: map['userId'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['createdAt'] ?? 0),
        articleCount: map['articleCount'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name'        : name,
        'userId'      : userId,
        'createdAt'   : createdAt.millisecondsSinceEpoch,
        'articleCount': articleCount,
      };
}

class BookmarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Lấy danh sách thư mục ─────────────────────────────────────
  Future<List<BookmarkFolder>> getFolders(String userId) async {
    final snap = await _db
        .collection('bookmark_folders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt')
        .get();
    return snap.docs
        .map((d) => BookmarkFolder.fromMap(d.data(), d.id))
        .toList();
  }

  // ── Tạo thư mục mới ───────────────────────────────────────────
  Future<BookmarkFolder> createFolder(
      String userId, String name) async {
    final doc = await _db.collection('bookmark_folders').add({
      'name'        : name.trim(),
      'userId'      : userId,
      'createdAt'   : DateTime.now().millisecondsSinceEpoch,
      'articleCount': 0,
    });
    return BookmarkFolder(
      id: doc.id,
      name: name.trim(),
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  // ── Xoá thư mục (và tất cả bookmark trong đó) ─────────────────
  Future<void> deleteFolder(String folderId) async {
    final batch = _db.batch();
    // Xoá các bài trong thư mục
    final items = await _db
        .collection('bookmarks')
        .where('folderId', isEqualTo: folderId)
        .get();
    for (final d in items.docs) batch.delete(d.reference);
    batch.delete(_db.collection('bookmark_folders').doc(folderId));
    await batch.commit();
  }

  // ── Đổi tên thư mục ───────────────────────────────────────────
  Future<void> renameFolder(String folderId, String newName) async {
    await _db
        .collection('bookmark_folders')
        .doc(folderId)
        .update({'name': newName.trim()});
  }

  // ── Kiểm tra bài đã bookmark chưa ─────────────────────────────
  Future<bool> isBookmarked(
      String userId, String articleId) async {
    final snap = await _db
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('articleId', isEqualTo: articleId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Lấy folderId bài đang bookmark trong (null = chưa bookmark)
  Future<String?> getBookmarkFolder(
      String userId, String articleId) async {
    final snap = await _db
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('articleId', isEqualTo: articleId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first['folderId'] as String?;
  }

  // ── Lưu bài vào thư mục ───────────────────────────────────────
  Future<void> addBookmark({
    required String userId,
    required String folderId,
    required ArticleModel article,
  }) async {
    // Đảm bảo article metadata tồn tại
    final articleRef = _db.collection('articles').doc(article.id);
    final articleDoc = await articleRef.get();
    if (!articleDoc.exists) await articleRef.set(article.toFirestore());

    final batch = _db.batch();
    final bookmarkRef = _db
        .collection('bookmarks')
        .doc('${userId}_${article.id}');

    batch.set(bookmarkRef, {
      'userId'     : userId,
      'articleId'  : article.id,
      'folderId'   : folderId,
      'savedAt'    : DateTime.now().millisecondsSinceEpoch,
    });
    batch.update(
        _db.collection('bookmark_folders').doc(folderId),
        {'articleCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ── Xoá bookmark ──────────────────────────────────────────────
  Future<void> removeBookmark({
    required String userId,
    required String articleId,
  }) async {
    final snap = await _db
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('articleId', isEqualTo: articleId)
        .get();
    if (snap.docs.isEmpty) return;

    final folderId = snap.docs.first['folderId'] as String;
    final batch    = _db.batch();
    batch.delete(snap.docs.first.reference);
    batch.update(
        _db.collection('bookmark_folders').doc(folderId),
        {'articleCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  // ── Lấy bài trong thư mục ─────────────────────────────────────
  Future<List<ArticleModel>> getArticlesInFolder(
      String folderId) async {
    final snap = await _db
        .collection('bookmarks')
        .where('folderId', isEqualTo: folderId)
        .orderBy('savedAt', descending: true)
        .get();

    final articles = <ArticleModel>[];
    for (final d in snap.docs) {
      final articleId = d['articleId'] as String;
      final articleDoc =
          await _db.collection('articles').doc(articleId).get();
      if (articleDoc.exists) {
        articles.add(ArticleModel.fromFirestore(articleDoc.data()!));
      }
    }
    return articles;
  }

  // ── Tất cả bài đã bookmark của user ───────────────────────────
  Future<List<ArticleModel>> getAllBookmarks(String userId) async {
    final snap = await _db
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .get();

    final articles = <ArticleModel>[];
    for (final d in snap.docs) {
      final articleDoc = await _db
          .collection('articles')
          .doc(d['articleId'])
          .get();
      if (articleDoc.exists) {
        articles.add(ArticleModel.fromFirestore(articleDoc.data()!));
      }
    }
    return articles;
  }
}
