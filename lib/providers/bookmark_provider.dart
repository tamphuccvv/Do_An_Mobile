// lib/providers/bookmark_provider.dart

import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/bookmark_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkService _svc = BookmarkService();

  List<BookmarkFolder> _folders    = [];
  Set<String>          _bookmarked = {};
  bool                 _loading    = false;

  List<BookmarkFolder> get folders => _folders;
  bool                 get loading => _loading;

  bool isBookmarked(String id) => _bookmarked.contains(id);

  // ── Tải thư mục & trạng thái bookmark ─────────────────────────
  Future<void> load(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      _folders = await _svc.getFolders(userId);
      final all = await _svc.getAllBookmarks(userId);
      _bookmarked = all.map((a) => a.id).toSet();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Tạo thư mục ───────────────────────────────────────────────
  Future<void> createFolder(String userId, String name) async {
    final folder = await _svc.createFolder(userId, name);
    _folders.add(folder);
    notifyListeners();
  }

  // ── Đổi tên thư mục ───────────────────────────────────────────
  Future<void> renameFolder(String folderId, String newName, String userId) async {
    await _svc.renameFolder(folderId, newName);
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      // Tạo object mới vì BookmarkFolder không có copyWith
      _folders[idx] = BookmarkFolder(
        id: _folders[idx].id,
        name: newName.trim(),
        userId: userId,
        createdAt: _folders[idx].createdAt,
        articleCount: _folders[idx].articleCount,
      );
      notifyListeners();
    }
  }

  // ── Xoá thư mục ───────────────────────────────────────────────
  Future<void> deleteFolder(String folderId, String userId) async {
    await _svc.deleteFolder(folderId);
    _folders.removeWhere((f) => f.id == folderId);
    notifyListeners();
    final all = await _svc.getAllBookmarks(userId);
    _bookmarked = all.map((a) => a.id).toSet();
    notifyListeners();
  }

  // ── Lưu bài vào thư mục ───────────────────────────────────────
  Future<void> addBookmark({
    required String userId,
    required String folderId,
    required ArticleModel article,
  }) async {
    await _svc.addBookmark(
        userId: userId, folderId: folderId, article: article);
    _bookmarked.add(article.id);
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      _folders[idx].articleCount++;
    }
    notifyListeners();
  }

  // ── Xoá bookmark ──────────────────────────────────────────────
  Future<void> removeBookmark(String userId, String articleId) async {
    await _svc.removeBookmark(userId: userId, articleId: articleId);
    _bookmarked.remove(articleId);
    await load(userId);
  }

  // ── Lấy bài trong thư mục ─────────────────────────────────────
  Future<List<ArticleModel>> getArticlesInFolder(String folderId) =>
      _svc.getArticlesInFolder(folderId);
}