// lib/providers/article_provider.dart

import 'package:flutter/material.dart';
import '../../models/article_model.dart';
import '../../models/comment_model.dart';
import '../../services/api_service.dart';
import '../../services/local_db_service.dart';

class ArticleProvider extends ChangeNotifier {
  final ApiService    _api   = ApiService();
  final LocalDbService _local = LocalDbService();

  List<ArticleModel> _articles    = [];
  List<ArticleModel> _searchResults = [];
  Set<String>        _likedIds    = {};
  bool   _loading      = false;
  bool   _searchLoading = false;
  String _error        = '';
  String _selectedCategory = 'Tất cả';
  int    _page         = 1;
  bool   _hasMore      = true;

  List<ArticleModel> get articles       => _articles;
  List<ArticleModel> get searchResults  => _searchResults;
  bool   get loading       => _loading;
  bool   get searchLoading => _searchLoading;
  String get error         => _error;
  String get selectedCategory => _selectedCategory;
  bool   get hasMore       => _hasMore;

  bool isLiked(String id) => _likedIds.contains(id);
  final List<ArticleModel> _bookmarkedArticles = [];
  List<ArticleModel> get bookmarkedArticles => _bookmarkedArticles;

  bool isBookmarked(ArticleModel article) => _bookmarkedArticles.contains(article);

  void toggleBookmark(ArticleModel article) {
    if (_bookmarkedArticles.contains(article)) {
      _bookmarkedArticles.remove(article);
    } else {
      _bookmarkedArticles.add(article);
    }
    notifyListeners(); // Thông báo để UI cập nhật ngay lập tức
  }
  // ── Tải bài báo (có phân trang) ──────────────────────────────
  Future<void> loadArticles({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page    = 1;
      _hasMore = true;
      _articles = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error   = '';
    notifyListeners();

    try {
      final fetched = await _api.fetchArticles(
        category: _selectedCategory,
        page: _page,
      );
      if (fetched.isEmpty) {
        _hasMore = false;
      } else {
        _articles.addAll(fetched);
        _page++;
      }
    } catch (e) {
      _error = e.toString();
      // Fallback: load from SQLite cache
      if (_page == 1) {
        _articles = await _local.getCachedArticles();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
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
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchLoading = true;
    notifyListeners();
    try {
      _searchResults = await _api.searchArticles(query);
    } catch (e) {
      _searchResults = [];
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  // ── Cache bài đang xem ────────────────────────────────────────
  Future<void> cacheArticle(ArticleModel article) async {
    await _local.cacheArticle(article);
  }

  // ── Toggle like ───────────────────────────────────────────────
  Future<void> toggleLike(
      String userId, ArticleModel article) async {
    final newLiked =
    await _api.toggleLike(userId, article.id, article);

    if (newLiked) {
      _likedIds.add(article.id);
      article.likesCount++;
    } else {
      _likedIds.remove(article.id);
      article.likesCount--;
    }
    notifyListeners();
  }

  // ── Tải danh sách đã like của user ───────────────────────────
  Future<void> loadLikedIds(String userId) async {
    final ids = await _api.getLikedArticleIds(userId);
    _likedIds = ids.toSet();
    notifyListeners();
  }

  // ── Bài đã like / đã comment (Profile) ───────────────────────
  Future<List<ArticleModel>> getLikedArticles(String userId) =>
      _api.getLikedArticles(userId);

  Future<List<ArticleModel>> getCommentedArticles(String userId) =>
      _api.getCommentedArticles(userId);

  // ── Comments ─────────────────────────────────────────────────
  Stream<List<CommentModel>> getComments(String articleId) =>
      _api.getComments(articleId);

  Future<void> addComment(
      CommentModel comment, ArticleModel article) async {
    await _api.addComment(comment, article);
    article.commentsCount++;
    notifyListeners();
  }

  Future<void> deleteComment(
      String commentId, String articleId) async {
    await _api.deleteComment(commentId, articleId);
  }
}