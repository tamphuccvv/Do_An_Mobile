// lib/screens/detail/article_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/article_model.dart';
import '../../providers/article_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/tts_service.dart';
import '../../services/ai_service.dart';
import '../../utils/constants.dart';
import '../bookmarks/bookmarks_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final TtsService _ttsService = TtsService();
  final AiService _aiService = AiService();

  bool _isTtsPlaying = false;
  bool _isLoadingSummary = false;
  String? _aiSummary;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
  }

  @override
  void dispose() {
    _ttsService.stop(); // Dừng đọc khi thoát màn hình
    super.dispose();
  }

  // ─── XỬ LÝ ĐỌC BÁO (TTS) ──────────────────────────────────────────
  void _toggleTts() async {
    if (_isTtsPlaying) {
      await _ttsService.stop();
      setState(() => _isTtsPlaying = false);
    } else {
      setState(() => _isTtsPlaying = true);
      // Đọc tiêu đề xong nghỉ 1 chút rồi đọc nội dung
      await _ttsService.speak("${widget.article.title}. . . ${widget.article.content}");
      // Khi đọc xong tự tắt icon (Flutter TTS không hỗ trợ await hoàn hảo nên dùng cách đơn giản này)
    }
  }

  // ─── XỬ LÝ TÓM TẮT AI ─────────────────────────────────────────────
  void _generateSummary() async {
    setState(() => _isLoadingSummary = true);
    final summary = await _aiService.summarizeArticle(
      widget.article.title,
      widget.article.content,
    );
    setState(() {
      _aiSummary = summary;
      _isLoadingSummary = false;
    });
  }

  // ─── BOTTOM SHEET TÙY CHỈNH GIAO DIỆN & FONT ──────────────────────
  void _showFontSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Để Container bên trong tự lo màu nền
      builder: (ctx) {
        // Dùng Consumer để BottomSheet tự động vẽ lại ngay khi bấm đổi Theme
        return Consumer<ThemeProvider>(
          builder: (context, theme, child) {
            return Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.surf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề và CÔNG TẮC DARK MODE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tùy chỉnh giao diện đọc',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.text(context)),
                      ),
                      IconButton(
                        icon: Icon(
                          theme.isDark ? Icons.light_mode : Icons.dark_mode,
                          color: theme.isDark ? Colors.amber : Colors.blueGrey,
                          size: 28,
                        ),
                        onPressed: () => theme.toggleTheme(), // Bật tắt Dark Mode
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Kéo cỡ chữ
                  Row(
                    children: [
                      Icon(Icons.text_fields, size: 18, color: theme.sub(context)),
                      Expanded(
                        child: Slider(
                          value: theme.fontSize,
                          min: 12.0,
                          max: 24.0,
                          activeColor: AppColors.accent,
                          onChanged: (val) => theme.setFontSize(val),
                        ),
                      ),
                      Icon(Icons.text_fields, size: 28, color: theme.sub(context)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chọn Font (ĐÃ FIX LỖI OVERFLOW BẰNG WRAP)
                  Center(
                    child: Wrap(
                      spacing: 12, // Khoảng cách ngang giữa 2 nút
                      runSpacing: 10, // Khoảng cách dọc nếu bị rớt dòng
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.font == AppFontFamily.serif ? AppColors.accent : theme.bg(context),
                            foregroundColor: theme.font == AppFontFamily.serif ? Colors.white : theme.text(context),
                          ),
                          onPressed: () => theme.setFont(AppFontFamily.serif),
                          child: const Text('Serif (Truyền thống)'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.font == AppFontFamily.sansSerif ? AppColors.accent : theme.bg(context),
                            foregroundColor: theme.font == AppFontFamily.sansSerif ? Colors.white : theme.text(context),
                          ),
                          onPressed: () => theme.setFont(AppFontFamily.sansSerif),
                          child: const Text('Sans-Serif (Hiện đại)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final article = widget.article;

    return Scaffold(
      backgroundColor: theme.bg(context),
      appBar: AppBar(
        backgroundColor: theme.surf(context),
        iconTheme: IconThemeData(color: theme.text(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_format),
            tooltip: 'Tùy chỉnh Font',
            onPressed: () => _showFontSettings(context), // Đã cập nhật
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookmarksScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa bài báo
            CachedNetworkImage(
              imageUrl: article.imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: theme.div(context),
                child: const Icon(Icons.broken_image, size: 50),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nguồn và Thời gian
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(article.category, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text(article.author, style: TextStyle(color: theme.sub(context), fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tiêu đề
                  Text(
                    article.title,
                    style: theme.contentStyle.copyWith(
                      fontSize: theme.fontSize + 6, // Tiêu đề to hơn nội dung
                      fontWeight: FontWeight.bold,
                      color: theme.text(context),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Thanh công cụ Tương tác (AI & Nghe)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.surf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.div(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Nút Đọc báo (TTS)
                        TextButton.icon(
                          onPressed: _toggleTts,
                          icon: Icon(
                            _isTtsPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                            color: _isTtsPlaying ? Colors.red : AppColors.accent,
                          ),
                          label: Text(_isTtsPlaying ? 'Dừng đọc' : 'Nghe bài báo',
                              style: TextStyle(color: theme.text(context))),
                        ),

                        // Nút Tóm tắt AI
                        TextButton.icon(
                          onPressed: _isLoadingSummary ? null : _generateSummary,
                          icon: _isLoadingSummary
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, color: Colors.amber),
                          label: Text('Tóm tắt AI', style: TextStyle(color: theme.text(context))),
                        ),
                      ],
                    ),
                  ),

                  // Hộp hiển thị kết quả Tóm tắt AI
                  if (_aiSummary != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.font == AppFontFamily.serif ? const Color(0xFFFFF8E1) : theme.surf(context), // Màu giấy cuộn nếu dùng Serif
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Text('AI Tóm tắt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiSummary!,
                            style: theme.contentStyle.copyWith(fontStyle: FontStyle.italic, color: theme.text(context)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Nội dung bài viết chính
                  Text(
                    article.content,
                    style: theme.contentStyle.copyWith(color: theme.text(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}