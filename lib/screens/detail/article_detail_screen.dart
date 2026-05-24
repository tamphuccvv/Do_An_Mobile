// lib/screens/detail/article_detail_screen.dart
// Tích hợp: TTS (5), AI Summary (3), Font/Size (6), Bookmark (8), Deep Link (9)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/article_model.dart';
import '../../models/comment_model.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';
import '../../services/summarization_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/bookmark_service.dart';
import '../../utils/constants.dart';
import '../../widgets/comment_widget.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;
  final String?      userId;

  const ArticleDetailScreen({super.key, required this.article, this.userId});
  @override State<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl  = ScrollController();

  // Services
  final _tts       = TtsService();
  final _deepLink  = DeepLinkService();

  bool   _liked        = false;
  int    _likesCount   = 0;
  bool   _sending      = false;
  TtsState _ttsState   = TtsState.stopped;
  double _ttsRate      = 0.5;
  bool   _summaryLoading = false;
  String? _summary;
  bool   _summaryExpanded = false;
  bool   _bookmarked   = false;
  String? _bookmarkFolderId;

  @override
  void initState() {
    super.initState();
    final ap = context.read<ArticleProvider>();
    _liked     = ap.isLiked(widget.article.id);
    _likesCount = widget.article.likesCount;

    _tts.init();
    _tts.onStateChanged = (s) => setState(() => _ttsState = s);

    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    if (widget.userId == null) return;
    final bp = context.read<BookmarkProvider>();
    _bookmarked = bp.isBookmarked(widget.article.id);
    setState(() {});
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    _tts.dispose();
    super.dispose();
  }

  // ── Like ───────────────────────────────────────────────────────
  Future<void> _toggleLike() async {
    if (widget.userId == null) { _showLoginSnack(); return; }
    final ap = context.read<ArticleProvider>();
    await ap.toggleLike(widget.userId!, widget.article);
    setState(() {
      _liked      = ap.isLiked(widget.article.id);
      _likesCount = widget.article.likesCount;
    });
  }

  // ── TTS ────────────────────────────────────────────────────────
  void _toggleTts() {
    final fullText =
        '${widget.article.title}. ${widget.article.content}';
    if (_ttsState == TtsState.playing) {
      _tts.pause();
    } else if (_ttsState == TtsState.paused) {
      _tts.resume();
    } else {
      _tts.speak(fullText);
    }
  }

  void _stopTts() => _tts.stop();

  void _showTtsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          context.read<ThemeProvider>().surf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tốc độ đọc',
                  style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w700, fontSize: 18,
                      color: context.read<ThemeProvider>().text(context))),
              Slider(
                value: _ttsRate,
                min: 0.1, max: 1.0, divisions: 9,
                activeColor: AppColors.accent,
                label: '${(_ttsRate * 100).toStringAsFixed(0)}%',
                onChanged: (v) {
                  setS(() => _ttsRate = v);
                  setState(() => _ttsRate = v);
                  _tts.setSpeechRate(v);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chậm',
                      style: TextStyle(
                          color: context.read<ThemeProvider>().cap(context),
                          fontSize: 12)),
                  const SizedBox(width: 120),
                  Text('Nhanh',
                      style: TextStyle(
                          color: context.read<ThemeProvider>().cap(context),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AI Summary ─────────────────────────────────────────────────
  final _aiService = AiService();
  Future<void> _loadSummary() async {
    if (_summary != null) {
      setState(() => _summaryExpanded = !_summaryExpanded);
      return;
    }
    setState(() => _summaryLoading = true);
    final result = await _aiService.summarizeArticle(
      widget.article.title,
      widget.article.content,
    );
    setState(() {
      _summary = result;
      _summaryLoading = false;
      _summaryExpanded = true;
    });
  }

  // ── Bookmark ───────────────────────────────────────────────────
  Future<void> _handleBookmark() async {
    if (widget.userId == null) { _showLoginSnack(); return; }
    final bp = context.read<BookmarkProvider>();

    if (_bookmarked) {
      await bp.removeBookmark(widget.userId!, widget.article.id);
      setState(() => _bookmarked = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã bỏ lưu')));
      }
      return;
    }

    // Chọn thư mục
    await bp.load(widget.userId!);
    if (!mounted) return;

    if (bp.folders.isEmpty) {
      // Tạo thư mục "Lưu xem sau" mặc định
      await bp.createFolder(widget.userId!, 'Lưu xem sau');
    }

    final folderId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.read<ThemeProvider>().surf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FolderPickerSheet(folders: bp.folders),
    );

    if (folderId != null) {
      await bp.addBookmark(
          userId: widget.userId!,
          folderId: folderId,
          article: widget.article);
      setState(() { _bookmarked = true; _bookmarkFolderId = folderId; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã lưu vào bộ sưu tập')));
      }
    }
  }

  // ── Deep Link Share ────────────────────────────────────────────
  Future<void> _share() async {
    await _deepLink.shareArticle(
      articleId: widget.article.id,
      title: widget.article.title,
      imageUrl: widget.article.imageUrl,
    );
  }

  // ── Comment ────────────────────────────────────────────────────
  Future<void> _sendComment() async {
    if (widget.userId == null) { _showLoginSnack(); return; }
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    final auth = context.read<AuthProvider>();
    final ap   = context.read<ArticleProvider>();

    final comment = CommentModel(
      id: '',
      userId: widget.userId!,
      articleId: widget.article.id,
      content: text,
      username: auth.user?.username ?? 'Ẩn danh',
      userAvatar: auth.user?.avatarUrl,
      createdAt: DateTime.now(),
    );

    final ok = await ap.addComment(comment, widget.article,
        userId: widget.userId);

    if (!ok && ap.moderationError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.accent,
        content: Text(ap.moderationError!,
            style: const TextStyle(color: Colors.white)),
      ));
      ap.clearModerationError();
    } else {
      _commentCtrl.clear();
    }
    setState(() => _sending = false);
  }

  void _showLoginSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.textPrimary,
      content: const Text('Đăng nhập để tương tác',
          style: TextStyle(color: Colors.white)),
      action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: AppColors.accent,
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.login)),
    ));
  }

  // ── Font / size sheet ──────────────────────────────────────────
  void _showTextSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          context.read<ThemeProvider>().surf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _TextSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final ap    = context.watch<ArticleProvider>();
    final theme = context.watch<ThemeProvider>();
    final catColor =
        AppColors.categoryColors[widget.article.category] ?? AppColors.accent;

    final bg   = theme.bg(context);
    final surf = theme.surf(context);
    final txt  = theme.text(context);
    final sub  = theme.sub(context);
    final cap  = theme.cap(context);
    final acc  = theme.acc(context);
    final div  = theme.div(context);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero ─────────────────────────────────────────
                Stack(children: [
                  if (widget.article.imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.article.imageUrl,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(height: 240, color: div),

                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        // ── Bookmark button ─────────────────────
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          radius: 18,
                          child: IconButton(
                            icon: Icon(
                              _bookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _bookmarked
                                  ? AppColors.accent
                                  : Colors.white,
                              size: 18,
                            ),
                            onPressed: _handleBookmark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // ── Text settings ───────────────────────
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.text_fields,
                                color: Colors.white, size: 18),
                            onPressed: _showTextSettings,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: catColor,
                        child: Text(
                          widget.article.category.toUpperCase(),
                          style: GoogleFonts.robotoCondensed(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(widget.article.title,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 24, fontWeight: FontWeight.w700,
                              color: txt, height: 1.3)),
                      const SizedBox(height: 10),

                      // ── Meta row (Đã sửa) ──────────────────────────────────────────
                      Row(children: [
                        // Bọc Text tác giả vào Expanded để nó tự động co lại nếu quá dài
                        Expanded(
                          child: Text(
                            widget.article.author,
                            style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sub),
                            maxLines: 1, // Ép chỉ nằm trên 1 dòng
                            overflow: TextOverflow.ellipsis, // Nếu dài quá thì hiện dấu "..."
                          ),
                        ),
                        Text('  ·  ', style: TextStyle(color: cap)),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(widget.article.publishedAt),
                          style: GoogleFonts.roboto(fontSize: 12, color: cap),
                        ),
                      ]),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: div),
                      ),

                      // ── Action bar ────────────────────────────
                      Row(children: [
                        _ActionBtn(
                          icon: _liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: '$_likesCount',
                          color: _liked ? acc : cap,
                          onTap: _toggleLike,
                        ),
                        const SizedBox(width: 14),
                        _ActionBtn(
                          icon: Icons.chat_bubble_outline,
                          label: '${widget.article.commentsCount}',
                          color: cap,
                          onTap: () {},
                        ),
                        const SizedBox(width: 14),

                        // TTS button
                        GestureDetector(
                          onTap: _toggleTts,
                          onLongPress: _showTtsSheet,
                          child: Row(children: [
                            Icon(
                              _ttsState == TtsState.playing
                                  ? Icons.pause_circle_outline
                                  : _ttsState == TtsState.paused
                                      ? Icons.play_circle_outline
                                      : Icons.headphones_outlined,
                              size: 20, color: _ttsState != TtsState.stopped ? acc : cap,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _ttsState == TtsState.playing
                                  ? 'Dừng'
                                  : _ttsState == TtsState.paused
                                      ? 'Tiếp'
                                      : 'Nghe',
                              style: GoogleFonts.roboto(
                                  fontSize: 13, color: cap,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),

                        if (_ttsState != TtsState.stopped) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _stopTts,
                            child: Icon(Icons.stop_circle_outlined,
                                size: 20, color: acc),
                          ),
                        ],

                        const Spacer(),
                        _ActionBtn(
                          icon: Icons.share_outlined,
                          label: 'Chia sẻ',
                          color: sub,
                          onTap: _share,
                        ),
                      ]),

                      // TTS progress indicator
                      if (_ttsState == TtsState.playing)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(
                            backgroundColor: div,
                            color: acc,
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: div),
                      ),

                      // ── AI Summary box ────────────────────────
                      GestureDetector(
                        onTap: _loadSummary,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.accLight(context),
                            border: Border.all(color: acc.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.auto_awesome,
                                    color: acc, size: 16),
                                const SizedBox(width: 6),
                                Text('Tóm tắt AI',
                                    style: GoogleFonts.robotoCondensed(
                                        color: acc,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        fontSize: 13)),
                                const Spacer(),
                                if (_summaryLoading)
                                  SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: acc),
                                  )
                                else
                                  Icon(
                                    _summaryExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: acc, size: 18,
                                  ),
                              ]),
                              if (_summaryExpanded && _summary != null) ...[
                                const SizedBox(height: 8),
                                Text(_summary!,
                                    style: GoogleFonts.merriweather(
                                        fontSize: 13,
                                        color: txt,
                                        height: 1.6,
                                        fontStyle: FontStyle.italic)),
                              ] else if (!_summaryExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Nhấn để xem tóm tắt',
                                      style: GoogleFonts.roboto(
                                          color: acc, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Content ───────────────────────────────
                      Text(widget.article.content,
                          style: theme.contentStyle.copyWith(color: txt)),

                      const SizedBox(height: 16),

                      // Source
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: theme.accLight(context),
                        child: Row(children: [
                          Icon(Icons.link, color: acc, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nguồn: ${widget.article.sourceUrl}',
                              style: GoogleFonts.roboto(
                                  fontSize: 11, color: acc),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      Text('Bình luận',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: txt)),
                      Divider(color: txt, thickness: 2),
                    ],
                  ),
                ),

                // ── Comments ─────────────────────────────────────
                StreamBuilder(
                  stream: ap.getComments(widget.article.id),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent)),
                      );
                    }
                    final comments = snap.data!;
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('Chưa có bình luận nào.',
                              style: GoogleFonts.merriweather(
                                  color: cap, fontSize: 13,
                                  fontStyle: FontStyle.italic)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (_, i) => CommentWidget(
                        comment: comments[i],
                        canDelete: auth.isAdmin ||
                            comments[i].userId == auth.user?.id,
                        onDelete: () => ap.deleteComment(
                            comments[i].id, widget.article.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // ── Comment input ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: surf,
            border: Border(top: BorderSide(color: div)),
          ),
          padding: EdgeInsets.fromLTRB(
              12, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: theme.contentStyle.copyWith(
                    fontSize: 13, color: txt),
                decoration: InputDecoration(
                  hintText: AppStrings.writeComment,
                  hintStyle: GoogleFonts.roboto(color: cap, fontSize: 13),
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            _sending
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: acc)))
                : IconButton(
                    onPressed: _sendComment,
                    icon: Icon(Icons.send, color: acc)),
          ]),
        ),
      ]),
    );
  }
}

// ── Font/Size bottom sheet ────────────────────────────────────────
class _TextSettingsSheet extends StatelessWidget {
  const _TextSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final surf  = theme.surf(context);
    final txt   = theme.text(context);
    final sub   = theme.sub(context);
    final cap   = theme.cap(context);
    final acc   = theme.acc(context);
    final div   = theme.div(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Tùy chỉnh văn bản',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, color: txt)),
        const SizedBox(height: 16),

        // Cỡ chữ
        Text('Cỡ chữ: ${theme.fontSize.toStringAsFixed(0)}pt',
            style: GoogleFonts.roboto(color: sub, fontSize: 13)),
        Row(children: [
          GestureDetector(
            onTap: () => theme.setFontSize(theme.fontSize - 1),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: div,
              child: Text('A−', style: GoogleFonts.roboto(color: txt)),
            ),
          ),
          Expanded(
            child: Slider(
              value: theme.fontSize,
              min: 12, max: 24, divisions: 6,
              activeColor: acc, inactiveColor: div,
              onChanged: (v) => theme.setFontSize(v),
            ),
          ),
          GestureDetector(
            onTap: () => theme.setFontSize(theme.fontSize + 1),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: div,
              child: Text('A+', style: GoogleFonts.roboto(color: txt)),
            ),
          ),
        ]),

        const SizedBox(height: 12),
        // Font
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => theme.setFont(AppFontFamily.serif),
              child: Container(
                padding: const EdgeInsets.all(12),
                color: theme.font == AppFontFamily.serif ? acc : div,
                child: Center(
                  child: Text('Serif',
                      style: GoogleFonts.merriweather(
                          color: theme.font == AppFontFamily.serif
                              ? Colors.white : txt)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => theme.setFont(AppFontFamily.sansSerif),
              child: Container(
                padding: const EdgeInsets.all(12),
                color: theme.font == AppFontFamily.sansSerif ? acc : div,
                child: Center(
                  child: Text('Sans-serif',
                      style: GoogleFonts.roboto(
                          color: theme.font == AppFontFamily.sansSerif
                              ? Colors.white : txt)),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Folder picker ─────────────────────────────────────────────────
class _FolderPickerSheet extends StatelessWidget {
  final List<BookmarkFolder> folders;
  const _FolderPickerSheet({required this.folders});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Lưu vào thư mục',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: theme.text(context))),
        const SizedBox(height: 12),
        ...folders.map((f) => ListTile(
              leading: const Icon(Icons.folder_outlined,
                  color: AppColors.accent),
              title: Text(f.name,
                  style: GoogleFonts.roboto(color: theme.text(context))),
              subtitle: Text('${f.articleCount} bài',
                  style: GoogleFonts.roboto(
                      color: theme.cap(context), fontSize: 12)),
              onTap: () => Navigator.pop(context, f.id),
            )),
      ]),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 13, color: color,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
