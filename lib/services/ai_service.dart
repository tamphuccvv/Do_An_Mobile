// lib/services/ai_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // Thay bằng API Key của bạn lấy từ: https://aistudio.google.com/
  static const String _apiKey = 'YAIzaSyCZc5csWny3Yo5vlYP_wfuhOuVJ9TfyosY';

  Future<String> summarizeArticle(String title, String content) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      return 'Vui lòng cung cấp API Key của Gemini để sử dụng tính năng tóm tắt.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);

      final prompt = '''
      Bạn là một trợ lý ảo chuyên tóm tắt tin tức. Hãy tóm tắt bài báo sau đây thành 3-4 câu ngắn gọn, súc tích và giữ lại những ý chính quan trọng nhất.
      
      Tiêu đề: $title
      Nội dung: $content
      
      Tóm tắt:
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Không thể tạo bản tóm tắt lúc này.';
    } catch (e) {
      return 'Lỗi khi gọi AI: \$e';
    }
  }
}