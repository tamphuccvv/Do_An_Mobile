// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';
import '../models/comment_model.dart';
import '../utils/constants.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<ArticleModel>> fetchArticles({
    String category = 'Tất cả',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final query = AppStrings.categoryQuery[category] ?? '';
      String url;
      if (query.isEmpty || category == 'Tất cả' || category == 'Vlog') {
        url = '$kNewsApiBase/everything'
            '?q=việt nam'
            '&language=vi&sortBy=publishedAt'
            '&pageSize=$pageSize&page=$page&apiKey=$kNewsApiKey';
      } else {
        url = '$kNewsApiBase/everything'
            '?q=$category'
            '&language=vi&sortBy=publishedAt'
            '&pageSize=$pageSize&page=$page&apiKey=$kNewsApiKey';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['articles'] as List)
            .where((a) => a['title'] != null && a['title'] != '[Removed]' && a['url'] != null)
            .map((a) => ArticleModel.fromNewsApi(a, category))
            .toList();
      } else {
        throw 'Lỗi API: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Không thể tải tin tức: $e';
    }
  }

  Future<List<ArticleModel>> searchArticles(String query) async {
    try {
      final url = '$kNewsApiBase/everything'
          '?q=${Uri.encodeComponent(query)}'
          '&language=vi&sortBy=relevancy&pageSize=30&apiKey=$kNewsApiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['articles'] as List)
            .where((a) => a['title'] != null && a['title'] != '[Removed]')
            .map((a) => ArticleModel.fromNewsApi(a, 'Tất cả'))
            .toList();
      } else { throw 'Lỗi: ${response.statusCode}'; }
    } catch (e) { throw 'Lỗi tìm kiếm: $e'; }
  }

  Future<void> ensureArticleExists(ArticleModel article) async {
    final ref = _db.collection('articles').doc(article.id);
    if (!(await ref.get()).exists) await ref.set(article.toFirestore());
  }

  Future<Map<String, int>> getArticleMeta(String articleId) async {
    final doc = await _db.collection('articles').doc(articleId).get();
    if (doc.exists) {
      return {'likesCount': doc['likesCount'] ?? 0, 'commentsCount': doc['commentsCount'] ?? 0};
    }
    return {'likesCount': 0, 'commentsCount': 0};
  }

  Future<bool> isLiked(String userId, String articleId) async {
    return (await _db.collection('likes').doc('${userId}_$articleId').get()).exists;
  }

  Future<bool> toggleLike(String userId, String articleId, ArticleModel article) async {
    await ensureArticleExists(article);
    final likeRef    = _db.collection('likes').doc('${userId}_$articleId');
    final articleRef = _db.collection('articles').doc(articleId);
    final liked      = await isLiked(userId, articleId);
    final batch      = _db.batch();
    if (liked) {
      batch.delete(likeRef);
      batch.update(articleRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {'userId': userId, 'articleId': articleId,
          'createdAt': DateTime.now().millisecondsSinceEpoch});
      batch.update(articleRef, {'likesCount': FieldValue.increment(1)});
    }
    await batch.commit();
    return !liked;
  }

  Future<List<String>> getLikedArticleIds(String userId) async {
    final snap = await _db.collection('likes').where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => d['articleId'] as String).toList();
  }

  Future<List<ArticleModel>> getLikedArticles(String userId) async {
    final ids = await getLikedArticleIds(userId);
    if (ids.isEmpty) return [];
    final articles = <ArticleModel>[];
    for (final id in ids) {
      final doc = await _db.collection('articles').doc(id).get();
      if (doc.exists) articles.add(ArticleModel.fromFirestore(doc.data()!));
    }
    return articles;
  }

  Stream<List<CommentModel>> getComments(String articleId) {
    return _db.collection('comments')
        .where('articleId', isEqualTo: articleId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addComment(CommentModel comment, ArticleModel article) async {
    await ensureArticleExists(article);
    final batch      = _db.batch();
    final commentRef = _db.collection('comments').doc();
    final articleRef = _db.collection('articles').doc(comment.articleId);
    batch.set(commentRef, comment.toMap());
    batch.update(articleRef, {'commentsCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteComment(String commentId, String articleId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('comments').doc(commentId));
    batch.update(_db.collection('articles').doc(articleId),
        {'commentsCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<List<ArticleModel>> getCommentedArticles(String userId) async {
    final snap = await _db.collection('comments').where('userId', isEqualTo: userId).get();
    final ids  = snap.docs.map((d) => d['articleId'] as String).toSet().toList();
    final articles = <ArticleModel>[];
    for (final id in ids) {
      final doc = await _db.collection('articles').doc(id).get();
      if (doc.exists) articles.add(ArticleModel.fromFirestore(doc.data()!));
    }
    return articles;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _db.collection('users').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> deleteUser(String uid) => _db.collection('users').doc(uid).delete();

  Future<void> toggleAdmin(String uid, bool current) =>
      _db.collection('users').doc(uid).update({'isAdmin': !current});

  Future<List<CommentModel>> getAllComments() async {
    final snap = await _db.collection('comments')
        .orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList();
  }
}
