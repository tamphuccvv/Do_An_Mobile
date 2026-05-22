// lib/services/moderation_service.dart
// Tính năng 2: Kiểm duyệt Bình luận Tự động
//
// Kiến trúc 2 lớp:
//   Layer 1 – Rule-based (offline, tức thì):
//     Kiểm tra toxic keywords, spam pattern, ALL_CAPS, URL spam
//   Layer 2 – ML via Perspective API (Google, free):
//     Gọi API để lấy toxicity score cho comment phức tạp hơn
//
// Nếu Layer 1 đã phát hiện → block ngay, không cần Layer 2.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

enum ModerationResult { safe, toxic, spam, blocked }

class ModerationService {
  // Thay bằng key của bạn tại https://perspectiveapi.com/
  static const _perspectiveKey = 'YOUR_PERSPECTIVE_API_KEY';
  static const _perspectiveUrl =
      'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze'
      '?key=$_perspectiveKey';

  // ── Kiểm tra bình luận ────────────────────────────────────────
  // Trả về (result, reason)
  Future<(ModerationResult, String)> check(String text) async {
    // ── Layer 1: Rule-based ──────────────────────────────────
    final lower = text.toLowerCase().trim();

    // Quá ngắn hoặc rỗng
    if (lower.length < 2) {
      return (ModerationResult.spam, 'Bình luận quá ngắn.');
    }

    // Spam: lặp ký tự (aaaaaaaa)
    if (RegExp(r'(.)\1{5,}').hasMatch(lower)) {
      return (ModerationResult.spam, 'Phát hiện spam ký tự lặp.');
    }

    // Spam: quá nhiều dấu chấm than/hỏi
    if (RegExp(r'[!?]{4,}').hasMatch(text)) {
      return (ModerationResult.spam, 'Phát hiện spam dấu câu.');
    }

    // ALL CAPS (hơn 80% chữ hoa, trên 10 ký tự)
    if (text.length > 10) {
      final upper  = text.replaceAll(RegExp(r'[^A-ZÀ-Ỹ]'), '').length;
      final letters = text.replaceAll(RegExp(r'[^A-Za-zÀ-ỹà-ỹ]'), '').length;
      if (letters > 0 && upper / letters > 0.8) {
        return (ModerationResult.spam, 'Bình luận viết HOA toàn bộ.');
      }
    }

    // URL spam
    if (RegExp(r'https?://\S+').allMatches(text).length > 2) {
      return (ModerationResult.spam, 'Phát hiện spam đường dẫn.');
    }

    // Toxic keywords
    for (final kw in AppStrings.toxicKeywords) {
      if (lower.contains(kw)) {
        return (ModerationResult.toxic,
        'Bình luận chứa từ ngữ không phù hợp.');
      }
    }

    // ── Layer 2: Perspective API ─────────────────────────────
    if (_perspectiveKey != 'YOUR_PERSPECTIVE_API_KEY') {
      try {
        final score = await _perspectiveScore(text);
        if (score >= 0.85) {
          return (ModerationResult.toxic,
          'Bình luận bị từ chối tự động (điểm độc hại: ${(score * 100).toStringAsFixed(0)}%).');
        }
      } catch (_) {
        // Nếu API lỗi → vẫn cho qua (fail-open)
      }
    }

    return (ModerationResult.safe, '');
  }

  // ── Gọi Perspective API ───────────────────────────────────────
  Future<double> _perspectiveScore(String text) async {
    final body = jsonEncode({
      'comment': {'text': text},
      'languages': ['vi', 'en'],
      'requestedAttributes': {'TOXICITY': {}},
    });
    final response = await http
        .post(Uri.parse(_perspectiveUrl),
        headers: {'Content-Type': 'application/json'},
        body: body)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['attributeScores']['TOXICITY']
      ['summaryScore']['value'] as num)
          .toDouble();
    }
    throw Exception('Perspective API error: ${response.statusCode}');
  }
}