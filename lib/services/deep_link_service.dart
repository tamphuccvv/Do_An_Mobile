// lib/services/deep_link_service.dart
// Tính năng 9: Chia sẻ Deep Link (Firebase Dynamic Links)

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share_plus/share_plus.dart';

class DeepLinkService {
  final FirebaseDynamicLinks _fdl = FirebaseDynamicLinks.instance;

  // Domain này cần tạo trong Firebase Console → Dynamic Links
  static const _domain = 'https://newsflow.page.link';
  // Package name của Android app
  static const _androidPkg = 'com.example.news_app';
  // Bundle ID của iOS app
  static const _iosBundleId = 'com.example.newsApp';

  // ── Tạo dynamic link cho bài báo ─────────────────────────────
  Future<String> createArticleLink({
    required String articleId,
    required String title,
    required String imageUrl,
  }) async {
    try {
      final params = DynamicLinkParameters(
        link: Uri.parse('$_domain/article?id=${Uri.encodeComponent(articleId)}'),
        uriPrefix: _domain,
        androidParameters: AndroidParameters(
          packageName: _androidPkg,
          minimumVersion: 0,
        ),
        iosParameters: IOSParameters(
          bundleId: _iosBundleId,
          minimumVersion: '0',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: title,
          description: 'Đọc bài báo này trên NewsFlow',
          imageUrl: imageUrl.isNotEmpty ? Uri.parse(imageUrl) : null,
        ),
        navigationInfoParameters: const NavigationInfoParameters(
          forcedRedirectEnabled: true,
        ),
      );

      final link = await _fdl.buildShortLink(params);
      return link.shortUrl.toString();
    } catch (_) {
      // Fallback: trả về link thường nếu Dynamic Links lỗi
      return '$_domain/article?id=${Uri.encodeComponent(articleId)}';
    }
  }

  // ── Chia sẻ bài báo kèm deep link ────────────────────────────
  Future<void> shareArticle({
    required String articleId,
    required String title,
    required String imageUrl,
  }) async {
    final link = await createArticleLink(
      articleId: articleId,
      title: title,
      imageUrl: imageUrl,
    );
    await Share.share(
      '$title\n\nĐọc thêm trên NewsFlow:\n$link',
      subject: title,
    );
  }

  // ── Xử lý deep link khi app được mở từ link ──────────────────
  // Gọi trong initState của HomeScreen
  Future<String?> getInitialArticleId() async {
    final data = await _fdl.getInitialLink();
    return _extractArticleId(data?.link);
  }

  // Lắng nghe deep link khi app đang chạy
  Stream<String?> get onArticleLink {
    return _fdl.onLink.map((d) => _extractArticleId(d.link));
  }

  String? _extractArticleId(Uri? link) {
    if (link == null) return null;
    return link.queryParameters['id'];
  }
}
