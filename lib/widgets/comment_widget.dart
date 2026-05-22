// lib/widgets/comment_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/comment_model.dart';
import '../../utils/constants.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final bool canDelete;
  final VoidCallback? onDelete;

  const CommentWidget({
    super.key,
    required this.comment,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ────────────────────────────────────────────
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accentLight,
            backgroundImage: comment.userAvatar != null
                ? NetworkImage(comment.userAvatar!)
                : null,
            child: comment.userAvatar == null
                ? Text(
              comment.username.isNotEmpty
                  ? comment.username[0].toUpperCase()
                  : '?',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 10),

          // ── Content ───────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'vi'),
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.textCaption,
                      ),
                    ),
                    if (canDelete) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.accent),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: GoogleFonts.merriweather(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}