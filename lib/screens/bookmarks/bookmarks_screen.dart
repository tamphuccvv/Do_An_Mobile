// lib/screens/bookmarks/bookmarks_screen.dart
// Tính năng 8: Bộ sưu tập

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/article_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/bookmark_service.dart';
import '../../utils/constants.dart';
import '../../widgets/article_card.dart';
import '../detail/article_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) context.read<BookmarkProvider>().load(uid);
    });
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final uid  = context.read<AuthProvider>().user?.id;
    if (uid == null) return;

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.read<ThemeProvider>().surf(context),
        title: Text('Thư mục mới',
            style: GoogleFonts.playfairDisplay(
                color: context.read<ThemeProvider>().text(context))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tên thư mục'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Tạo',
                  style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      await context.read<BookmarkProvider>().createFolder(uid, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp    = context.watch<BookmarkProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg(context),
      appBar: AppBar(
        backgroundColor: theme.surf(context),
        iconTheme: IconThemeData(color: theme.text(context)),
        title: Text('Bộ sưu tập',
            style: GoogleFonts.playfairDisplay(
                color: theme.text(context), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createFolder,
            tooltip: 'Thư mục mới',
          ),
        ],
      ),
      body: bp.loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.accent))
          : bp.folders.isEmpty
          ? _EmptyFolders(onCreate: _createFolder)
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bp.folders.length,
        separatorBuilder: (_, __) => Divider(
            color: theme.div(context), height: 1),
        itemBuilder: (_, i) {
          final folder = bp.folders[i];
          return _FolderTile(folder: folder);
        },
      ),
    );
  }
}

// ── Tile thư mục ─────────────────────────────────────────────────
class _FolderTile extends StatelessWidget {
  final BookmarkFolder folder;
  const _FolderTile({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bp    = context.read<BookmarkProvider>();
    final uid   = context.read<AuthProvider>().user?.id ?? '';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        color: AppColors.accentLight,
        child: const Icon(Icons.folder_outlined, color: AppColors.accent),
      ),
      title: Text(folder.name,
          style: GoogleFonts.playfairDisplay(
              color: theme.text(context), fontWeight: FontWeight.w600)),
      subtitle: Text('${folder.articleCount} bài',
          style: GoogleFonts.roboto(
              color: theme.cap(context), fontSize: 12)),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: theme.cap(context)),
        onSelected: (v) async {
          if (v == 'delete') {
            await bp.deleteFolder(folder.id, uid);
          } else if (v == 'rename') {
            final ctrl = TextEditingController(text: folder.name);
            final name = await showDialog<String>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Đổi tên'),
                content: TextField(controller: ctrl, autofocus: true),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Huỷ')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, ctrl.text),
                      child: const Text('Lưu',
                          style: TextStyle(color: AppColors.accent))),
                ],
              ),
            );
            if (name != null && name.trim().isNotEmpty) {
              await bp.renameFolder(folder.id, name, uid);
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
          const PopupMenuItem(
              value: 'delete',
              child: Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FolderDetailScreen(folder: folder)),
      ),
    );
  }
}

// ── Chi tiết thư mục ─────────────────────────────────────────────
class FolderDetailScreen extends StatefulWidget {
  final BookmarkFolder folder;
  const FolderDetailScreen({super.key, required this.folder});
  @override State<FolderDetailScreen> createState() =>
      _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<ArticleModel> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final articles = await context
          .read<BookmarkProvider>()
          .getArticlesInFolder(widget.folder.id);

      if (mounted) {
        setState(() { _articles = articles; });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải bài viết trong thư mục: $e');
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final uid   = context.read<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: theme.bg(context),
      appBar: AppBar(
        backgroundColor: theme.surf(context),
        iconTheme: IconThemeData(color: theme.text(context)),
        title: Text(widget.folder.name,
            style: GoogleFonts.playfairDisplay(
                color: theme.text(context), fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.accent))
          : _articles.isEmpty
          ? Center(
          child: Text('Thư mục trống',
              style: GoogleFonts.merriweather(
                  color: theme.cap(context),
                  fontStyle: FontStyle.italic)))
          : ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (_, i) => ArticleCard(
          article: _articles[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                  article: _articles[i], userId: uid),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyFolders({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_border,
              size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text('Chưa có thư mục nào',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Tạo thư mục để lưu bài báo yêu thích',
              style: GoogleFonts.roboto(
                  color: AppColors.textCaption, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                elevation: 0),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Tạo thư mục',
                style: GoogleFonts.robotoCondensed(
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}