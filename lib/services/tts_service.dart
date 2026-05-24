// lib/services/tts_service.dart
// Tính năng 5: Đọc báo bằng Giọng nói (Text-to-Speech)

import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { stopped, playing, paused }

class TtsService {
  final FlutterTts _tts = FlutterTts();
  TtsState state = TtsState.stopped;

  // Callback để UI cập nhật
  void Function(TtsState)? onStateChanged;

  Future<void> init() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.5);   // 0.0 – 1.0 (0.5 = bình thường)
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Fallback sang en-US nếu vi-VN không có
    final langs = await _tts.getLanguages as List?;
    if (langs != null && !langs.contains('vi-VN')) {
      await _tts.setLanguage('en-US');
    }

    _tts.setStartHandler(() {
      state = TtsState.playing;
      onStateChanged?.call(state);
    });
    _tts.setCompletionHandler(() {
      state = TtsState.stopped;
      onStateChanged?.call(state);
    });
    _tts.setPauseHandler(() {
      state = TtsState.paused;
      onStateChanged?.call(state);
    });
    _tts.setContinueHandler(() {
      state = TtsState.playing;
      onStateChanged?.call(state);
    });
    _tts.setErrorHandler((msg) {
      state = TtsState.stopped;
      onStateChanged?.call(state);
    });
  }

  // Đọc văn bản (chia nhỏ để tránh giới hạn ký tự)
  Future<void> speak(String text) async {
    if (state == TtsState.playing) await stop();
    // Chia thành đoạn <= 500 ký tự tại dấu câu
    final chunks = _splitText(text, 500);
    for (final chunk in chunks) {
      if (state == TtsState.stopped && chunk != chunks.first) break;
      await _tts.speak(chunk);
    }
  }

  Future<void> pause() async {
    if (state == TtsState.playing) await _tts.pause();
  }

  Future<void> resume() async {
    if (state == TtsState.paused) await _tts.speak('');
  }

  Future<void> stop() async {
    await _tts.stop();
    state = TtsState.stopped;
    onStateChanged?.call(state);
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
  }

  Future<void> dispose() async => _tts.stop();

  // ── Chia văn bản thành chunks ─────────────────────────────────
  List<String> _splitText(String text, int maxLen) {
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    var current = '';
    for (final s in sentences) {
      if ((current + s).length > maxLen && current.isNotEmpty) {
        chunks.add(current.trim());
        current = s;
      } else {
        current += ' $s';
      }
    }
    if (current.trim().isNotEmpty) chunks.add(current.trim());
    return chunks.isEmpty ? [text] : chunks;
  }
}
