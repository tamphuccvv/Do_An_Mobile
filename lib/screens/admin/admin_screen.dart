// lib/screens/admin/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/api_service.dart';
import '../../models/comment_model.dart';
import '../../utils/constants.dart';
import '../../widgets/comment_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _users = [];
  List<CommentModel> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final users = await _api.getAllUsers();
      final comments = await _api.getAllComments();
      setState(() {
        _users = users;
        _comments = comments;
      });
    } catch (e) {
      debugPrint('Admin load error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(String uid, bool currentIsAdmin) async {
    await _api.toggleAdmin(uid, currentIsAdmin);
    await _loadData();
  }

  Future<void> _deleteUser(String uid) async {
    await _api.deleteUser(uid);
    await _loadData();
  }

  Future<void> _deleteComment(String commentId, String articleId) async {
    await _api.deleteComment(commentId, articleId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: Text('Quản trị viên',
              style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          bottom: TabBar(
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textCaption,
            indicatorColor: AppColors.accent,
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
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.accent))
            : TabBarView(
          children: [
            _buildUsersTab(),
            _buildCommentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        final bool isAdmin = u['isAdmin'] ?? false;
        return ListTile(
          tileColor: AppColors.surface,
          leading: CircleAvatar(
            backgroundColor: AppColors.accentLight,
            child: Text(
              u['username'].toString().isNotEmpty ? u['username'][0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
          title: Text(u['username'] ?? 'Ẩn danh',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          subtitle: Text(u['email'] ?? ''),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text(isAdmin ? 'Huỷ Admin' : 'Cấp Admin'),
                onTap: () => _toggleAdmin(u['id'], isAdmin),
              ),
              PopupMenuItem(
                child: const Text('Xoá người dùng', style: TextStyle(color: Colors.red)),
                onTap: () => _deleteUser(u['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    return ListView.builder(
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final c = _comments[index];
        return CommentWidget(
          comment: c,
          canDelete: true,
          onDelete: () => _deleteComment(c.id, c.articleId),
        );
      },
    );
  }
}