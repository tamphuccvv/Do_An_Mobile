// lib/screens/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/comment_model.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/comment_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _users    = [];
  List<CommentModel>         _comments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final users    = await _api.getAllUsers();
      final comments = await _api.getAllComments();
      setState(() { _users = users; _comments = comments; });
    } catch (e) {
      debugPrint('Admin load error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(String uid, bool isAdmin) async {
    await _api.toggleAdmin(uid, isAdmin);
    await _loadData();
  }

  Future<void> _deleteUser(String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc muốn xoá người dùng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) { await _api.deleteUser(uid); await _loadData(); }
  }

  Future<void> _deleteComment(String id, String articleId) async {
    await _api.deleteComment(id, articleId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.bg(context),
        appBar: AppBar(
          backgroundColor: theme.surf(context),
          elevation: 0,
          iconTheme: IconThemeData(color: theme.text(context)),
          title: Text('Quản trị viên',
              style: GoogleFonts.playfairDisplay(
                  color: theme.text(context),
                  fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Tải lại'),
          ],
          bottom: TabBar(
            labelColor: theme.acc(context),
            unselectedLabelColor: theme.cap(context),
            indicatorColor: theme.acc(context),
            indicatorWeight: 2,
            labelStyle: GoogleFonts.robotoCondensed(
                fontWeight: FontWeight.w700, letterSpacing: 0.8),
            tabs: const [
              Tab(text: 'NGƯỜI DÙNG'),
              Tab(text: 'BÌNH LUẬN'),
            ],
          ),
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(color: theme.acc(context)))
            : TabBarView(children: [
                _buildUsersTab(theme),
                _buildCommentsTab(theme),
              ]),
      ),
    );
  }

  Widget _buildUsersTab(ThemeProvider theme) {
    if (_users.isEmpty) {
      return Center(
          child: Text('Chưa có người dùng',
              style: GoogleFonts.merriweather(color: theme.cap(context))));
    }
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => Divider(
          color: theme.div(context), height: 1),
      itemBuilder: (context, i) {
        final u       = _users[i];
        final isAdmin = u['isAdmin'] ?? false;
        return ListTile(
          tileColor: theme.surf(context),
          leading: CircleAvatar(
            backgroundColor: theme.accLight(context),
            child: Text(
              (u['username'] ?? '?').toString().isNotEmpty
                  ? u['username'].toString()[0].toUpperCase() : '?',
              style: TextStyle(color: theme.acc(context)),
            ),
          ),
          title: Row(children: [
            Flexible(
              child: Text(u['username'] ?? 'Ẩn danh',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: theme.text(context))),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                color: theme.acc(context),
                child: Text('ADMIN',
                    style: GoogleFonts.robotoCondensed(
                        color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ],
          ]),
          subtitle: Text(u['email'] ?? '',
              style: GoogleFonts.roboto(
                  color: theme.cap(context), fontSize: 12)),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.cap(context)),
            onSelected: (v) {
              if (v == 'admin') _toggleAdmin(u['id'], isAdmin);
              if (v == 'delete') _deleteUser(u['id']);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'admin',
                child: Text(isAdmin ? 'Huỷ Admin' : 'Cấp Admin'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Xoá người dùng',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab(ThemeProvider theme) {
    if (_comments.isEmpty) {
      return Center(
          child: Text('Chưa có bình luận nào',
              style: GoogleFonts.merriweather(
                  color: theme.cap(context),
                  fontStyle: FontStyle.italic)));
    }
    return ListView.builder(
      itemCount: _comments.length,
      itemBuilder: (_, i) {
        final c = _comments[i];
        return CommentWidget(
          comment: c,
          canDelete: true,
          onDelete: () => _deleteComment(c.id, c.articleId),
        );
      },
    );
  }
}
