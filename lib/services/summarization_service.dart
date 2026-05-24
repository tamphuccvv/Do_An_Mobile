// lib/services/summarization_service.dart
// Tính năng 3: Tóm tắt bài báo bằng AI
//
// Dùng Anthropic Claude API (free tier) để tóm tắt.
// Fallback: extractive summarization (offline, chọn 3 câu quan trọng nhất).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SummarizationService {
  // Lấy key tại https://console.anthropic.com
  static const _claudeKey = 'YAIzaSyCZc5csWny3Yo5vlYP_wfuhOuVJ9TfyosY';
  static const _claudeUrl = 'https://api.anthropic.com/v1/messages';

  // ── Tóm tắt bài báo ──────────────────────────────────────────
  // Trả về summary string; cache theo articleId
  Future<String> summarize({
    required String articleId,
    required String title,
    required String content,
  }) async {
    // Kiểm tra cache trước
    final cached = await _getCache(articleId);
    if (cached != null) return cached;

    // Thử Claude API
    if (_claudeKey != 'YAIzaSyCZc5csWny3Yo5vlYP_wfuhOuVJ9TfyosY') {
      try {
        final result = await _claudeSummarize(title, content);
        await _setCache(articleId, result);
        return result;
      } catch (_) {
        // Fallback extractive
      }
    }

    // Extractive fallback (offline)
    final result = _extractiveSummarize(content);
    await _setCache(articleId, result);
    return result;
  }

  // ── Claude API ────────────────────────────────────────────────
  Future<String> _claudeSummarize(String title, String content) async {
    final prompt =
        'Bạn là biên tập viên tin tức. Hãy tóm tắt bài báo sau thành '
        '3-4 câu ngắn gọn bằng tiếng Việt, nêu đúng ý chính, '
        'không thêm ý kiến cá nhân.\n\n'
        'Tiêu đề: $title\n\nNội dung:\n$content\n\n'
        'Tóm tắt:';

    final response = await http
        .post(
          Uri.parse(_claudeUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _claudeKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 300,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'].toString().trim();
    }
    throw Exception('Claude API error: ${response.statusCode}');
  }

  // ── Extractive summarization (offline) ───────────────────────
  // Chọn 3 câu có TF-IDF score cao nhất
  String _extractiveSummarize(String content) {
    // Tách câu
    final sentences = content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().length > 20)
        .toList();

    if (sentences.length <= 3) return content.trim();

    // Tính từ xuất hiện nhiều nhất (term frequency)
    final allWords = content
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toList();
    final tf = <String, int>{};
    for (final w in allWords) {
      tf[w] = (tf[w] ?? 0) + 1;
    }

    // Score từng câu = tổng TF của các từ trong câu
    final scored = sentences.asMap().entries.map((e) {
      final idx   = e.key;
      final sent  = e.value;
      final words = sent.toLowerCase().split(RegExp(r'\s+'));
      double score = words.fold(0.0, (s, w) => s + (tf[w] ?? 0).toDouble());
      // Ưu tiên câu đầu (thường là lead)
      if (idx == 0) score *= 1.5;
      return _ScoredSentence(idx, sent, score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Lấy top 3, sắp xếp lại theo thứ tự xuất hiện
    final top3 = scored.take(3).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return top3.map((s) => s.sentence.trim()).join(' ');
  }

  // ── Cache (SharedPreferences) ─────────────────────────────────
  Future<String?> _getCache(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('summary_$articleId');
  }

  Future<void> _setCache(String articleId, String summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('summary_$articleId', summary);
  }
}

class _ScoredSentence {
  final int    index;
  final String sentence;
  final double score;
  _ScoredSentence(this.index, this.sentence, this.score);
}
