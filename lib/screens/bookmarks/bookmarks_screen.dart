import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/article_provider.dart'; // Nơi chứa list bài báo đã lưu
import '../../widgets/article_card.dart';
import '../detail/article_detail_screen.dart'; // Widget hiển thị thẻ bài báo

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bộ sưu tập')),
      body: Consumer<ArticleProvider>(
        builder: (context, provider, child) {
          final bookmarks = provider.bookmarkedArticles;
          if (bookmarks.isEmpty) {
            return const Center(child: Text('Bạn chưa lưu bài báo nào!'));
          }
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) => ArticleCard(
              article: bookmarks[index],
              onTap: () {
                // Khi bấm vào bài đã lưu trong Bộ sưu tập, chuyển hướng đến trang chi tiết
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(article: bookmarks[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}