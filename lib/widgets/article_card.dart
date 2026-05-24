// lib/widgets/article_card.dart
// Tích hợp: Dark Mode (ThemeProvider), Bookmark quick-save

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/article_model.dart';
import '../providers/theme_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final bool isFeature;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.isFeature = false,
  });

  @override
  Widget build(BuildContext context) {
    return isFeature
        ? _FeatureCard(article: article, onTap: onTap)
        : _CompactCard(article: article, onTap: onTap);
  }
}

// ── Bookmark icon (dùng chung) ────────────────────────────────────
class _BookmarkIcon extends StatelessWidget {
  final ArticleModel article;
  final Color color;
  const _BookmarkIcon({required this.article, required this.color});

  @override
  Widget build(BuildContext context) {
    final bp   = context.watch<BookmarkProvider>();
    final auth = context.watch<AuthProvider>();
    final saved = bp.isBookmarked(article.id);

    return GestureDetector(
      onTap: () async {
        if (auth.user == null) return;
        if (saved) {
          await bp.removeBookmark(auth.user!.id, article.id);
        } else {
          await bp.load(auth.user!.id);
          if (bp.folders.isEmpty) {
            await bp.createFolder(auth.user!.id, 'Lưu xem sau');
          }
          await bp.addBookmark(
            userId: auth.user!.id,
            folderId: bp.folders.first.id,
            article: article,
          );
        }
      },
      child: Icon(
        saved ? Icons.bookmark : Icons.bookmark_border,
        size: 18,
        color: saved ? AppColors.accent : color,
      ),
    );
  }
}

// ── Feature Card ─────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  const _FeatureCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme    = context.watch<ThemeProvider>();
    final catColor = AppColors.categoryColors[article.category] ?? AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.surf(context),
          border: Border.all(color: theme.div(context)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: theme.bg(context),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(color: theme.bg(context),
                      child: Icon(Icons.image_not_supported,
                          color: theme.cap(context))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: catColor,
                      child: Text(article.category.toUpperCase(),
                          style: GoogleFonts.robotoCondensed(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    ),
                    const Spacer(),
                    _BookmarkIcon(article: article, color: theme.cap(context)),
                  ]),
                  const SizedBox(height: 8),
                  Text(article.title,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: theme.text(context), height: 1.3),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (article.summary.isNotEmpty)
                    Text(article.summary,
                        style: GoogleFonts.merriweather(
                            fontSize: 13, color: theme.sub(context), height: 1.5),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  _MetaRow(article: article),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact Card ─────────────────────────────────────────────────
class _CompactCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  const _CompactCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme    = context.watch<ThemeProvider>();
    final catColor = AppColors.categoryColors[article.category] ?? AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surf(context),
          border: Border(bottom: BorderSide(color: theme.div(context))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 3, height: 14, color: catColor,
                        margin: const EdgeInsets.only(right: 6)),
                    Flexible(child: Text(article.category,
                        style: GoogleFonts.robotoCondensed(
                            color: catColor, fontSize: 11,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8))),
                    const Spacer(),
                    _BookmarkIcon(article: article, color: theme.cap(context)),
                  ]),
                  const SizedBox(height: 4),
                  Text(article.title,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: theme.text(context), height: 1.3),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _MetaRow(article: article, small: true),
                ],
              ),
            ),
            if (article.imageUrl.isNotEmpty) ...[
              const SizedBox(width: 10),
              CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: 90, height: 80, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    width: 90, height: 80, color: theme.bg(context),
                    child: Icon(Icons.image, color: theme.cap(context), size: 20)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Meta row ─────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final ArticleModel article;
  final bool small;
  const _MetaRow({required this.article, this.small = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final sz    = small ? 11.0 : 12.0;
    return Row(children: [
      Flexible(
        child: Text(article.author,
            style: GoogleFonts.roboto(fontSize: sz, fontWeight: FontWeight.w600,
                color: theme.sub(context)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      Text('  ·  ', style: TextStyle(fontSize: sz, color: theme.cap(context))),
      Text(timeago.format(article.publishedAt, locale: 'vi'),
          style: GoogleFonts.roboto(fontSize: sz, color: theme.cap(context))),
      const Spacer(),
      Icon(Icons.favorite_border, size: sz + 1, color: theme.cap(context)),
      const SizedBox(width: 2),
      Text('${article.likesCount}',
          style: TextStyle(fontSize: sz, color: theme.cap(context))),
      const SizedBox(width: 8),
      Icon(Icons.chat_bubble_outline, size: sz + 1, color: theme.cap(context)),
      const SizedBox(width: 2),
      Text('${article.commentsCount}',
          style: TextStyle(fontSize: sz, color: theme.cap(context))),
    ]);
  }
}
