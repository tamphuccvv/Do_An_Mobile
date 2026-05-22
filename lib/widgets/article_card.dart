// lib/widgets/article_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/article_model.dart';
import '../../utils/constants.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final bool isFeature; // bài lớn đầu trang

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.isFeature = false,
  });

  @override
  Widget build(BuildContext context) {
    return isFeature ? _FeatureCard(article: article, onTap: onTap)
        : _CompactCard(article: article, onTap: onTap);
  }
}

// ── Bài nổi bật (ảnh lớn, full width) ──────────────────────────
class _FeatureCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  const _FeatureCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[article.category]
        ?? AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ảnh ──────────────────────────────────────────────
            if (article.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.textCaption),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category tag ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    color: catColor,
                    child: Text(
                      article.category.toUpperCase(),
                      style: GoogleFonts.robotoCondensed(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Tiêu đề ───────────────────────────────────
                  Text(
                    article.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // ── Summary ───────────────────────────────────
                  if (article.summary.isNotEmpty)
                    Text(
                      article.summary,
                      style: GoogleFonts.merriweather(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),

                  // ── Meta ──────────────────────────────────────
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

// ── Bài nhỏ (ảnh bên phải, text bên trái) ───────────────────────
class _CompactCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  const _CompactCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[article.category]
        ?? AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Text ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        color: catColor,
                        margin: const EdgeInsets.only(right: 6),
                      ),
                      Text(
                        article.category,
                        style: GoogleFonts.robotoCondensed(
                          color: catColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    article.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(article: article, small: true),
                ],
              ),
            ),

            // ── Ảnh nhỏ ─────────────────────────────────────────
            if (article.imageUrl.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  width: 90,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 90,
                    height: 80,
                    color: AppColors.background,
                    child: const Icon(Icons.image,
                        color: AppColors.textCaption, size: 20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Meta: author · time · likes · comments ───────────────────────
class _MetaRow extends StatelessWidget {
  final ArticleModel article;
  final bool small;
  const _MetaRow({required this.article, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 11.0 : 12.0;
    return Row(
      children: [
        Text(
          article.author,
          style: GoogleFonts.roboto(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '  ·  ',
          style: TextStyle(
              fontSize: size, color: AppColors.textCaption),
        ),
        Text(
          timeago.format(article.publishedAt, locale: 'vi'),
          style: GoogleFonts.roboto(
              fontSize: size, color: AppColors.textCaption),
        ),
        const Spacer(),
        Icon(Icons.favorite_border, size: size + 1,
            color: AppColors.textCaption),
        const SizedBox(width: 2),
        Text('${article.likesCount}',
            style: TextStyle(
                fontSize: size, color: AppColors.textCaption)),
        const SizedBox(width: 8),
        Icon(Icons.chat_bubble_outline, size: size + 1,
            color: AppColors.textCaption),
        const SizedBox(width: 2),
        Text('${article.commentsCount}',
            style: TextStyle(
                fontSize: size, color: AppColors.textCaption)),
      ],
    );
  }
}