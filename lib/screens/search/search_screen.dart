// lib/screens/search/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/article_card.dart';
import '../detail/article_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() { _ctrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      context.read<ArticleProvider>().search(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ap    = context.watch<ArticleProvider>();
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            color: theme.surf(context),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tìm kiếm',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: theme.text(context))),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.bg(context),
                    border: Border.all(color: theme.div(context)),
                  ),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.search, color: theme.cap(context), size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: _onChanged,
                        style: GoogleFonts.merriweather(
                            fontSize: 14, color: theme.text(context)),
                        decoration: InputDecoration(
                          hintText: 'Tìm bài báo, chủ đề...',
                          hintStyle: GoogleFonts.roboto(
                              color: theme.cap(context), fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_ctrl.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: theme.cap(context), size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          context.read<ArticleProvider>().search('');
                        },
                      ),
                  ]),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.div(context)),

          // Results
          Expanded(
            child: _ctrl.text.isEmpty
                ? _EmptyState()
                : ap.searchLoading
                    ? Center(child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.acc(context)))
                    : ap.searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy kết quả cho\n"${_ctrl.text}"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.merriweather(
                                  color: theme.cap(context), fontSize: 14,
                                  fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.builder(
                            itemCount: ap.searchResults.length,
                            itemBuilder: (_, i) {
                              final a = ap.searchResults[i];
                              return ArticleCard(
                                article: a,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        ArticleDetailScreen(
                                            article: a, userId: auth.user?.id))),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.newspaper, size: 56, color: theme.div(context)),
        const SizedBox(height: 16),
        Text('Tìm kiếm tin tức',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, color: theme.sub(context), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Nhập từ khóa để tìm bài báo',
            style: GoogleFonts.roboto(color: theme.cap(context), fontSize: 13)),
      ]),
    );
  }
}
