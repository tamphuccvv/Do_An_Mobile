// lib/screens/home/home_screen.dart
// Tích hợp: Gợi ý (1), Dark Mode (4), Bookmarks (8), Deep Link (9)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/article_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/article_card.dart';
import '../detail/article_detail_screen.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/deep_link_service.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _deepLink = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _initServices();
    _handleDeepLinks();
  }

  // Init FCM sau khi vào Home (không block splash)
  Future<void> _initServices() async {
    try {
      final auth  = context.read<AuthProvider>();
      final notif = NotificationService();
      await notif.init(auth.user?.id)
          .timeout(const Duration(seconds: 8), onTimeout: () {});
      await notif.subscribeBreakingNews();
    } catch (e) {
      debugPrint('FCM init error: \$e');
    }
  }

  // Xử lý deep link mở app
  Future<void> _handleDeepLinks() async {
    // App mở từ terminated
    final initialId = await _deepLink.getInitialArticleId();
    if (initialId != null && mounted) _openArticleById(initialId);

    // App đang chạy nhận deep link
    _deepLink.onArticleLink.listen((id) {
      if (id != null && mounted) _openArticleById(id);
    });
  }

  void _openArticleById(String articleId) {
    // Tìm article trong danh sách hiện tại
    final ap = context.read<ArticleProvider>();
    final articles = ap.articles;
    try {
      final article = articles.firstWhere((a) => a.id == articleId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(
            article: article,
            userId: context.read<AuthProvider>().user?.id,
          ),
        ),
      );
    } catch (_) {
      // Article chưa load → bỏ qua
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    final pages = [
      const _NewsTab(),
      const SearchScreen(),
      const BookmarksScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.bg(context),
      body: pages[_navIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.div(context))),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          backgroundColor: theme.surf(context),
          selectedItemColor: theme.acc(context),
          unselectedItemColor: theme.cap(context),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.robotoCondensed(
              fontWeight: FontWeight.w700, letterSpacing: 0.8),
          unselectedLabelStyle: GoogleFonts.robotoCondensed(),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.newspaper), label: 'Trang chủ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Tìm kiếm'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_border), label: 'Lưu'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
          ],
        ),
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.small(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminScreen())),
          backgroundColor: theme.text(context),
          child: const Icon(Icons.admin_panel_settings,
              color: Colors.white, size: 18))
          : null,
    );
  }
}

// ── Tab Tin tức ──────────────────────────────────────────────────
class _NewsTab extends StatefulWidget {
  const _NewsTab();
  @override State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap   = context.read<ArticleProvider>();
      final auth = context.read<AuthProvider>();
      ap.loadArticles(refresh: true);
      if (auth.user != null) {
        ap.loadLikedIds(auth.user!.id);
        ap.loadRecommendations(auth.user!.id);
        context.read<BookmarkProvider>().load(auth.user!.id);
      }
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
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _EditorialAppBar(tabCtrl: _tabCtrl)),
          _CategoryBar(),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _ArticleList(scrollCtrl: _scrollCtrl),
            _RecommendedList(),
          ],
        ),
      ),
    );
  }
}

// ── Masthead AppBar ───────────────────────────────────────────────
class _EditorialAppBar extends StatelessWidget {
  final TabController tabCtrl;
  const _EditorialAppBar({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final now   = DateTime.now();
    final days  = ['Chủ Nhật','Thứ Hai','Thứ Ba','Thứ Tư',
      'Thứ Năm','Thứ Sáu','Thứ Bảy'];
    final months = List.generate(12, (i) => 'Tháng ${i + 1}');
    final date = '${days[now.weekday % 7]}, ngày ${now.day} '
        '${months[now.month - 1]} ${now.year}';

    return Container(
      color: theme.surf(context),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        // Date + Settings icon
        Row(children: [
          Text(date,
              style: GoogleFonts.robotoCondensed(
                  fontSize: 11,
                  color: theme.cap(context),
                  letterSpacing: 1.5)),
          const Spacer(),
          // Dark mode toggle
          GestureDetector(
            onTap: () => theme.toggleTheme(),
            child: Icon(
                theme.isDark ? Icons.light_mode : Icons.dark_mode,
                color: theme.cap(context), size: 20),
          ),
          const SizedBox(width: 12),
          // Settings
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Icon(Icons.settings_outlined,
                color: theme.cap(context), size: 20),
          ),
        ]),
        const SizedBox(height: 8),
        Divider(color: theme.text(context), thickness: 3, height: 3),
        const SizedBox(height: 6),
        Text(AppStrings.appName,
            style: GoogleFonts.playfairDisplay(
                fontSize: 40, fontWeight: FontWeight.w900,
                color: theme.text(context), letterSpacing: -2)),
        const SizedBox(height: 4),
        Divider(color: theme.text(context), thickness: 1, height: 1),

        // Tab: Tất cả / Gợi ý cho bạn
        TabBar(
          controller: tabCtrl,
          labelColor: theme.acc(context),
          unselectedLabelColor: theme.cap(context),
          indicatorColor: theme.acc(context),
          indicatorWeight: 2,
          labelStyle: GoogleFonts.robotoCondensed(
              fontWeight: FontWeight.w700, letterSpacing: 0.8),
          tabs: const [
            Tab(text: 'TẤT CẢ'),
            Tab(text: 'GỢI Ý CHO BẠN'),
          ],
        ),
      ]),
    );
  }
}

// ── Category bar ──────────────────────────────────────────────────
class _CategoryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
        pinned: true, delegate: _CategoryDelegate());
  }
}

class _CategoryDelegate extends SliverPersistentHeaderDelegate {
  @override double get minExtent => 48;
  @override double get maxExtent => 48;

  @override
  Widget build(ctx, _, __) {
    final ap    = ctx.watch<ArticleProvider>();
    final theme = ctx.watch<ThemeProvider>();

    return Container(
      color: theme.surf(ctx),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: AppStrings.categories.length,
        itemBuilder: (_, i) {
          final cat      = AppStrings.categories[i];
          final selected = ap.selectedCategory == cat;
          final color    =
              AppColors.categoryColors[cat] ?? AppColors.accent;

          return GestureDetector(
            onTap: () => ap.selectCategory(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              color: selected ? color : theme.bg(ctx),
              child: Text(
                cat,
                style: GoogleFonts.robotoCondensed(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: selected ? Colors.white : theme.sub(ctx),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override bool shouldRebuild(_) => true;
}

// ── Danh sách bài báo ────────────────────────────────────────────
class _ArticleList extends StatelessWidget {
  final ScrollController scrollCtrl;
  const _ArticleList({required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final ap    = context.watch<ArticleProvider>();
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    if (ap.loading && ap.articles.isEmpty) return _ShimmerList();

    if (ap.error.isNotEmpty && ap.articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: theme.cap(context), size: 48),
              const SizedBox(height: 16),
              Text('Không thể tải tin tức',
                  style: GoogleFonts.playfairDisplay(
                      color: theme.text(context), fontSize: 18)),
              const SizedBox(height: 8),
              Text(ap.error,
                  style: GoogleFonts.roboto(
                      color: theme.cap(context), fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ap.loadArticles(refresh: true),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.acc(context))),
                child: Text('Thử lại',
                    style: GoogleFonts.roboto(
                        color: theme.acc(context))),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: theme.acc(context),
      onRefresh: () => ap.loadArticles(refresh: true),
      child: ListView.builder(
        controller: scrollCtrl,
        itemCount: ap.articles.length + 1,
        itemBuilder: (_, i) {
          if (i == ap.articles.length) {
            return ap.hasMore
                ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.acc(context))))
                : Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('— Hết tin —',
                    style: GoogleFonts.robotoCondensed(
                        color: theme.cap(context),
                        letterSpacing: 2)),
              ),
            );
          }
          final article = ap.articles[i];
          return ArticleCard(
            article: article,
            isFeature: i == 0,
            onTap: () {
              ap.cacheArticle(article, userId: auth.user?.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(
                      article: article, userId: auth.user?.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Danh sách gợi ý ──────────────────────────────────────────────
class _RecommendedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ap    = context.watch<ArticleProvider>();
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.recommend_outlined,
                  size: 56, color: theme.div(context)),
              const SizedBox(height: 16),
              Text('Đăng nhập để nhận gợi ý',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, color: theme.sub(context))),
              const SizedBox(height: 8),
              Text(
                'Chúng tôi sẽ gợi ý tin tức dựa trên\nbài bạn đã đọc và yêu thích.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    color: theme.cap(context), fontSize: 13,
                    height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (ap.loading && ap.recommended.isEmpty) return _ShimmerList();

    if (ap.recommended.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 48, color: theme.div(context)),
            const SizedBox(height: 12),
            Text('Đọc thêm bài để nhận gợi ý phù hợp',
                style: GoogleFonts.merriweather(
                    color: theme.cap(context),
                    fontStyle: FontStyle.italic,
                    fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: ap.recommended.length,
      itemBuilder: (_, i) {
        final article = ap.recommended[i];
        return ArticleCard(
          article: article,
          isFeature: i == 0,
          onTap: () {
            ap.cacheArticle(article, userId: auth.user?.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(
                    article: article, userId: auth.user?.id),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Shimmer.fromColors(
      baseColor: theme.div(context),
      highlightColor: theme.bg(context),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: i == 0 ? 280 : 100,
          color: theme.surf(context),
        ),
      ),
    );
  }
}