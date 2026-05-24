// lib/services/recommendation_service.dart
// Tính năng 1: Hệ thống Gợi ý Tin tức
//
// Thuật toán: Content-Based Filtering đơn giản
//  1. Thu thập "interest vector" từ hành vi user:
//     - Like (+3 điểm/category), Comment (+2), Đọc/cache (+1)
//  2. Tính điểm mỗi bài báo theo interest vector
//  3. Sắp xếp và trả về top N bài

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/article_model.dart';
import '../services/api_service.dart';

class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApiService        _api = ApiService();

  // ── Cập nhật interest khi user tương tác ─────────────────────
  // action: 'like'(3), 'comment'(2), 'read'(1)
  Future<void> trackInteraction({
    required String userId,
    required String category,
    required String action,
  }) async {
    final weight = action == 'like' ? 3 : action == 'comment' ? 2 : 1;
    final ref = _db
        .collection('user_interests')
        .doc(userId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      Map<String, dynamic> data = snap.exists ? snap.data()! : {};
      final current = (data[category] ?? 0) as int;
      data[category] = current + weight;
      data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      tx.set(ref, data);
    });
  }

  // ── Lấy interest vector của user ─────────────────────────────
  Future<Map<String, int>> getUserInterests(String userId) async {
    final doc = await _db
        .collection('user_interests')
        .doc(userId)
        .get();
    if (!doc.exists) return {};
    final data = doc.data()!..remove('updatedAt');
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ── Lưu interest vào SharedPreferences (offline) ─────────────
  Future<void> cacheInterests(
      String userId, Map<String, int> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'interests_$userId', jsonEncode(interests));
  }

  Future<Map<String, int>> getCachedInterests(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('interests_$userId');
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ── Gợi ý bài báo ────────────────────────────────────────────
  Future<List<ArticleModel>> getRecommendations({
    required String userId,
    required List<ArticleModel> allArticles,
    int topN = 10,
  }) async {
    // Lấy interest (Firestore → fallback cache)
    Map<String, int> interests;
    try {
      interests = await getUserInterests(userId);
      if (interests.isNotEmpty) cacheInterests(userId, interests);
    } catch (_) {
      interests = await getCachedInterests(userId);
    }

    if (interests.isEmpty) {
      // Chưa có dữ liệu → trả về bài mới nhất
      return allArticles.take(topN).toList();
    }

    // Tính điểm mỗi bài
    final totalWeight = interests.values.fold(0, (a, b) => a + b);

    final scored = allArticles.map((article) {
      final catScore  = interests[article.category] ?? 0;
      final recency   = _recencyScore(article.publishedAt);
      final engagement = (article.likesCount * 0.3 +
          article.commentsCount * 0.2);

      // Score = 50% interest + 30% recency + 20% engagement
      final score = (totalWeight > 0
              ? (catScore / totalWeight) * 50
              : 0) +
          recency * 30 +
          engagement * 20 / 100;

      return _ScoredArticle(article, score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topN).map((s) => s.article).toList();
  }

  // Recency: bài trong 2h → 1.0, trong 1 ngày → 0.7, tuần → 0.3
  double _recencyScore(DateTime publishedAt) {
    final hours = DateTime.now().difference(publishedAt).inHours;
    if (hours <= 2)   return 1.0;
    if (hours <= 24)  return 0.7;
    if (hours <= 168) return 0.3;
    return 0.1;
  }
}

class _ScoredArticle {
  final ArticleModel article;
  final double       score;
  _ScoredArticle(this.article, this.score);
}
