// lib/providers/article_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../models/comment_model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../services/recommendation_service.dart';
import '../services/moderation_service.dart';

class ArticleProvider extends ChangeNotifier {
  final ApiService            _api    = ApiService();
  final LocalDbService        _local  = LocalDbService();
  final RecommendationService _rec    = RecommendationService();
  final ModerationService     _mod    = ModerationService();

  List<ArticleModel> _articles         = [];
  List<ArticleModel> _recommended      = [];
  List<ArticleModel> _searchResults    = [];
  Set<String>        _likedIds         = {};
  bool   _loading        = false;
  bool   _searchLoading  = false;
  String _error          = '';
  String _selectedCategory = 'Tất cả';
  int    _page           = 1;
  bool   _hasMore        = true;

  // Moderation: lưu kết quả kiểm duyệt để hiện thông báo
  String? _moderationError;

  List<ArticleModel> get articles       => _articles;
  List<ArticleModel> get recommended    => _recommended;
  List<ArticleModel> get searchResults  => _searchResults;
  bool   get loading        => _loading;
  bool   get searchLoading  => _searchLoading;
  String get error          => _error;
  String get selectedCategory => _selectedCategory;
  bool   get hasMore        => _hasMore;
  String? get moderationError => _moderationError;

  bool isLiked(String id) => _likedIds.contains(id);

  // ── Tải bài báo ──────────────────────────────────────────────
  Future<void> loadArticles({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) { _page = 1; _hasMore = true; _articles = []; }
    if (!_hasMore) return;

    _loading = true; _error = '';
    notifyListeners();

    try {
      final fetched = await _api.fetchArticles(
          category: _selectedCategory, page: _page);
      if (fetched.isEmpty) {
        _hasMore = false;
      } else {
        _articles.addAll(fetched);
        _page++;
      }
    } catch (e) {
      _error = e.toString();
      if (_page == 1) _articles = await _local.getCachedArticles();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Tải gợi ý cho user ────────────────────────────────────────
  Future<void> loadRecommendations(String userId) async {
    if (_articles.isEmpty) await loadArticles(refresh: true);
    _recommended = await _rec.getRecommendations(
        userId: userId, allArticles: _articles);
    notifyListeners();
  }

  // ── Chọn category ────────────────────────────────────────────
  Future<void> selectCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadArticles(refresh: true);
  }

  // ── Tìm kiếm ─────────────────────────────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = []; notifyListeners(); return;
    }
    _searchLoading = true; notifyListeners();
    try {
      _searchResults = await _api.searchArticles(query);
    } catch (_) {
      _searchResults = [];
    } finally {
      _searchLoading = false; notifyListeners();
    }
  }

  // ── Cache + track "đọc" ───────────────────────────────────────
  Future<void> cacheArticle(ArticleModel article,
      {String? userId}) async {
    await _local.cacheArticle(article);
    if (userId != null) {
      await _rec.trackInteraction(
          userId: userId,
          category: article.category,
          action: 'read');
    }
  }

  // ── Toggle like ───────────────────────────────────────────────
  Future<void> toggleLike(String userId, ArticleModel article) async {
    final newLiked =
        await _api.toggleLike(userId, article.id, article);
    if (newLiked) {
      _likedIds.add(article.id);
      article.likesCount++;
      await _rec.trackInteraction(
          userId: userId, category: article.category, action: 'like');
    } else {
      _likedIds.remove(article.id);
      article.likesCount--;
    }
    notifyListeners();
  }

  Future<void> loadLikedIds(String userId) async {
    final ids = await _api.getLikedArticleIds(userId);
    _likedIds = ids.toSet();
    notifyListeners();
  }

  Future<List<ArticleModel>> getLikedArticles(String userId) =>
      _api.getLikedArticles(userId);

  Future<List<ArticleModel>> getCommentedArticles(String userId) =>
      _api.getCommentedArticles(userId);

  // ── Comments (với kiểm duyệt) ────────────────────────────────
  Stream<List<CommentModel>> getComments(String articleId) =>
      _api.getComments(articleId);

  /// Trả về true nếu gửi thành công, false nếu bị chặn kiểm duyệt
  Future<bool> addComment(
      CommentModel comment, ArticleModel article,
      {String? userId}) async {
    _moderationError = null;

    final (result, reason) = await _mod.check(comment.content);
    if (result != ModerationResult.safe) {
      _moderationError = reason;
      notifyListeners();
      return false;
    }

    await _api.addComment(comment, article);
    article.commentsCount++;

    if (userId != null) {
      await _rec.trackInteraction(
          userId: userId,
          category: article.category,
          action: 'comment');
    }
    notifyListeners();
    return true;
  }

  Future<void> deleteComment(
      String commentId, String articleId) =>
      _api.deleteComment(commentId, articleId);

  void clearModerationError() {
    _moderationError = null;
    notifyListeners();
  }
}
