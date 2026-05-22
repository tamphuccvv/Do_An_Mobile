// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/article_card.dart';
import '../detail/article_detail_screen.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final List<Widget> _pages = const [
    _NewsTab(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_navIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textCaption,
          selectedLabelStyle: GoogleFonts.robotoCondensed(
              fontWeight: FontWeight.w700, letterSpacing: 0.8),
          unselectedLabelStyle: GoogleFonts.robotoCondensed(),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.newspaper), label: 'Trang chủ'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Tìm kiếm'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
          ],
        ),
      ),
      // FAB Admin
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.small(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminScreen())),
        backgroundColor: AppColors.textPrimary,
        child: const Icon(Icons.admin_panel_settings,
            color: Colors.white, size: 18),
      )
          : null,
    );
  }
}

// ── Tab Tin tức chính ────────────────────────────────────────────
class _NewsTab extends StatefulWidget {
  const _NewsTab();
  @override State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap = context.read<ArticleProvider>();
      final auth = context.read<AuthProvider>();
      ap.loadArticles(refresh: true);
      if (auth.user != null) ap.loadLikedIds(auth.user!.id);
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 300) {
        context.read<ArticleProvider>().loadArticles();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _EditorialAppBar(),
          _CategoryBar(),
        ],
        body: _ArticleList(scrollCtrl: _scrollCtrl),
      ),
    );
  }
}

// ── Masthead AppBar ──────────────────────────────────────────────
class _EditorialAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days   = ['Chủ Nhật','Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy'];
    final months = ['Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5','Tháng 6',
      'Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'];
    final dateStr = '${days[now.weekday % 7]}, ngày ${now.day} ${months[now.month - 1]} ${now.year}';

    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            // Date + divider
            Text(dateStr,
                style: GoogleFonts.robotoCondensed(
                    fontSize: 11,
                    color: AppColors.textCaption,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            const Divider(color: AppColors.textPrimary, thickness: 3, height: 3),
            const SizedBox(height: 8),

            // Masthead
            Text(AppStrings.appName,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -2)),
            const SizedBox(height: 4),
            const Divider(color: AppColors.textPrimary, thickness: 1, height: 1),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Category bar ────────────────────────────────────────────────
class _CategoryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryDelegate(),
    );
  }
}

class _CategoryDelegate extends SliverPersistentHeaderDelegate {
  @override double get minExtent => 48;
  @override double get maxExtent => 48;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlap) {
    final ap = ctx.watch<ArticleProvider>();
    return Container(
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: AppStrings.categories.length,
        itemBuilder: (_, i) {
          final cat      = AppStrings.categories[i];
          final selected = ap.selectedCategory == cat;
          final color    = AppColors.categoryColors[cat] ?? AppColors.accent;

          return GestureDetector(
            onTap: () => ap.selectCategory(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: selected ? color : AppColors.background,
              child: Text(
                cat,
                style: GoogleFonts.robotoCondensed(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_) => true;
}

// ── Danh sách bài báo ────────────────────────────────────────────
class _ArticleList extends StatelessWidget {
  final ScrollController scrollCtrl;
  const _ArticleList({required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final ap   = context.watch<ArticleProvider>();
    final auth = context.watch<AuthProvider>();

    if (ap.loading && ap.articles.isEmpty) {
      return _ShimmerList();
    }

    if (ap.error.isNotEmpty && ap.articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off,
                  color: AppColors.textCaption, size: 48),
              const SizedBox(height: 16),
              Text('Không thể tải tin tức',
                  style: GoogleFonts.playfairDisplay(
                      color: AppColors.textPrimary, fontSize: 18)),
              const SizedBox(height: 8),
              Text(ap.error,
                  style: GoogleFonts.roboto(
                      color: AppColors.textCaption, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ap.loadArticles(refresh: true),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent)),
                child: Text('Thử lại',
                    style: GoogleFonts.roboto(color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ap.loadArticles(refresh: true),
      child: ListView.builder(
        controller: scrollCtrl,
        itemCount: ap.articles.length + 1,
        itemBuilder: (_, i) {
          if (i == ap.articles.length) {
            return ap.hasMore
                ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent)))
                : Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('— Hết tin —',
                    style: GoogleFonts.robotoCondensed(
                        color: AppColors.textCaption,
                        letterSpacing: 2)),
              ),
            );
          }

          final article = ap.articles[i];
          return ArticleCard(
            article: article,
            isFeature: i == 0,
            onTap: () {
              ap.cacheArticle(article);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(
                    article: article,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Shimmer loading ──────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: i == 0 ? 280 : 100,
          color: AppColors.surface,
        ),
      ),
    );
  }
}