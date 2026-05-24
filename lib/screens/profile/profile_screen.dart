// lib/screens/profile/profile_screen.dart
// Tích hợp: Dark Mode, Bookmarks link, Settings link

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/article_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/article_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/article_card.dart';
import '../detail/article_detail_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<ArticleModel> _liked     = [];
  List<ArticleModel> _commented = [];
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    setState(() => _loadingData = true);
    final ap = context.read<ArticleProvider>();
    _liked     = await ap.getLikedArticles(auth.user!.id);
    _commented = await ap.getCommentedArticles(auth.user!.id);
    setState(() => _loadingData = false);
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 512);
    if (file == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Upload avatar cần cấu hình Firebase Storage.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    if (!auth.isLoggedIn) return _NotLoggedIn();

    final user = auth.user!;

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Container(
              color: theme.surf(context),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Top row: Settings
                Row(children: [
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: theme.cap(context), size: 22),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ]),

                // Avatar
                Stack(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.accLight(context),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase() : '?',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 32, color: theme.acc(context),
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: theme.acc(context), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                Text(user.username,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: theme.text(context))),
                const SizedBox(height: 4),
                Text(user.email,
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: theme.cap(context))),

                if (user.isAdmin) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    color: theme.acc(context),
                    child: Text('ADMIN',
                        style: GoogleFonts.robotoCondensed(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                ],

                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _StatChip(label: 'Đã thích', value: _liked.length),
                  Container(width: 1, height: 32, color: theme.div(context)),
                  _StatChip(label: 'Bình luận', value: _commented.length),
                ]),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async { await auth.logout(); },
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.acc(context)),
                        shape: const RoundedRectangleBorder()),
                    child: Text(AppStrings.logout,
                        style: GoogleFonts.roboto(
                            color: theme.acc(context), fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(tabController: _tab, theme: context.read<ThemeProvider>()),
          ),
        ],
        body: _loadingData
            ? Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: context.read<ThemeProvider>().acc(context)))
            : TabBarView(
                controller: _tab,
                children: [
                  _ArticleGrid(articles: _liked),
                  _ArticleGrid(articles: _commented),
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Column(children: [
      Text('$value',
          style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: theme.text(context))),
      Text(label,
          style: GoogleFonts.roboto(fontSize: 12, color: theme.cap(context))),
    ]);
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final ThemeProvider theme;
  const _TabDelegate({required this.tabController, required this.theme});

  @override double get minExtent => 46;
  @override double get maxExtent => 46;

  @override
  Widget build(ctx, _, __) => Container(
    color: theme.surf(ctx),
    child: TabBar(
      controller: tabController,
      labelColor: theme.acc(ctx),
      unselectedLabelColor: theme.cap(ctx),
      indicatorColor: theme.acc(ctx),
      indicatorWeight: 2,
      labelStyle: GoogleFonts.robotoCondensed(
          fontWeight: FontWeight.w700, letterSpacing: 0.8),
      tabs: const [Tab(text: 'ĐÃ THÍCH'), Tab(text: 'ĐÃ BÌNH LUẬN')],
    ),
  );

  @override bool shouldRebuild(_) => false;
}

class _ArticleGrid extends StatelessWidget {
  final List<ArticleModel> articles;
  const _ArticleGrid({required this.articles});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    if (articles.isEmpty) {
      return Center(child: Text('Chưa có bài nào.',
          style: GoogleFonts.merriweather(
              color: theme.cap(context), fontStyle: FontStyle.italic)));
    }
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (_, i) => ArticleCard(
        article: articles[i],
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
                ArticleDetailScreen(article: articles[i]))),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.person_outline, size: 64, color: theme.div(context)),
          const SizedBox(height: 16),
          Text('Chưa đăng nhập',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: theme.text(context))),
          const SizedBox(height: 8),
          Text('Đăng nhập để xem hồ sơ và lưu bài yêu thích.',
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                  fontSize: 13, color: theme.sub(context), height: 1.6)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.acc(context),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(), elevation: 0),
              child: Text(AppStrings.login,
                  style: GoogleFonts.robotoCondensed(
                      fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}
