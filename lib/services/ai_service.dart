// lib/services/ai_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const String _apiKey = 'AIzaSyBc1K0t-y6kTXPFTObRKyHE7_IwXzjQqgI';

  Future<String> summarizeArticle(String title, String content) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _apiKey,
      );

      final prompt = '''
      Bạn là một trợ lý ảo chuyên tóm tắt tin tức. Hãy tóm tắt bài báo sau đây thành 3-4 câu ngắn gọn, súc tích và giữ lại những ý chính quan trọng nhất.
      
      Tiêu đề: $title
      Nội dung: $content
      
      Tóm tắt:
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Không thể tạo bản tóm tắt lúc này.';
    } catch (e) {
      return 'Lỗi khi gọi AI: $e';
    }
  }
}
