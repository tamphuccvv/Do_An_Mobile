// lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    await _flutterTts.setLanguage("vi-VN"); // Thiết lập giọng đọc tiếng Việt
    await _flutterTts.setSpeechRate(0.5);   // Tốc độ đọc vừa phải
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    _isPlaying = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _flutterTts.stop();
  }
}