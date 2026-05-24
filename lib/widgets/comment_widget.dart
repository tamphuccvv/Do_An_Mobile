// lib/widgets/comment_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment_model.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

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
    final theme = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.div(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.accLight(context),
            backgroundImage: comment.userAvatar != null
                ? NetworkImage(comment.userAvatar!) : null,
            child: comment.userAvatar == null
                ? Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase() : '?',
                    style: GoogleFonts.playfairDisplay(
                        color: theme.acc(context), fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(comment.username,
                      style: GoogleFonts.roboto(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: theme.text(context))),
                  const SizedBox(width: 6),
                  Text(timeago.format(comment.createdAt, locale: 'vi'),
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: theme.cap(context))),
                  if (canDelete) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline,
                          size: 16, color: theme.acc(context)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: GoogleFonts.merriweather(
                        fontSize: 13, color: theme.sub(context), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
