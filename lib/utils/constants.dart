// lib/utils/constants.dart

import 'package:flutter/material.dart';

// ─── NEWSAPI ────────────────────────────────────────────────────
const String kNewsApiKey  = '633e499895cd4ed8a7ad2051a666d359';
const String kNewsApiBase = 'https://newsapi.org/v2';

// ─── MÀUSẮC EDITORIAL (Light) ───────────────────────────────────
class AppColors {
  static const Color background    = Color(0xFFF8F5F0);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color divider       = Color(0xFFE0D9CF);

  static const Color textPrimary   = Color(0xFF1A1208);
  static const Color textSecondary = Color(0xFF6B5E4E);
  static const Color textCaption   = Color(0xFF9E9082);

  static const Color accent        = Color(0xFFC0392B);
  static const Color accentLight   = Color(0xFFFDECEC);

  static const Map<String, Color> categoryColors = {
    'Công nghệ': Color(0xFF2563EB),
    'Kinh tế'  : Color(0xFF059669),
    'Thể thao' : Color(0xFFD97706),
    'Giải trí' : Color(0xFF7C3AED),
    'Sức khoẻ' : Color(0xFF0891B2),
    'Thế giới' : Color(0xFFDC2626),
    'Vlog'     : Color(0xFFDB2777),
    'Tất cả'   : Color(0xFF374151),
  };
}

// ─── MÀUSẮC DARK MODE ───────────────────────────────────────────
class DarkColors {
  static const Color background    = Color(0xFF0F0F0F);
  static const Color surface       = Color(0xFF1C1C1E);
  static const Color divider       = Color(0xFF2C2C2E);

  static const Color textPrimary   = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFFAEAEB2);
  static const Color textCaption   = Color(0xFF636366);

  static const Color accent        = Color(0xFFFF453A);
  static const Color accentLight   = Color(0xFF3A1414);
}

// ─── CHUỖI ──────────────────────────────────────────────────────
class AppStrings {
  static const appName      = 'NewsFlow';
  static const tagline      = 'Tin tức · Báo chí · Vlog';
  static const writeComment = 'Viết bình luận...';

  static const login          = 'Đăng nhập';
  static const register       = 'Đăng ký';
  static const logout         = 'Đăng xuất';
  static const forgotPassword = 'Quên mật khẩu';
  static const email          = 'Email';
  static const password       = 'Mật khẩu';
  static const username       = 'Tên người dùng';

  static const home    = 'Trang chủ';
  static const search  = 'Tìm kiếm';
  static const profile = 'Hồ sơ';
  static const admin   = 'Quản trị';

  static const List<String> categories = [
    'Tất cả','Công nghệ','Kinh tế','Thể thao',
    'Giải trí','Sức khoẻ','Thế giới','Vlog',
  ];

  static const Map<String, String> categoryQuery = {
    'Tất cả'  : '',
    'Công nghệ': 'technology',
    'Kinh tế' : 'business',
    'Thể thao': 'sports',
    'Giải trí': 'entertainment',
    'Sức khoẻ': 'health',
    'Thế giới': 'general',
    'Vlog'    : 'vlog',
  };

  // Toxic keywords (kiểm duyệt đơn giản, fallback khi không có model)
  static const List<String> toxicKeywords = [
    'đm','đmm','vcl','vkl','clgt','lồn','cặc','địt','chết đi',
    'ngu','óc chó','thằng điên','con điên','mày chết','spam',
  ];
}

// ─── ROUTES ─────────────────────────────────────────────────────
class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';
  static const home           = '/home';
  static const articleDetail  = '/article-detail';
  static const profile        = '/profile';
  static const editProfile    = '/edit-profile';
  static const admin          = '/admin';
  static const search         = '/search';
  static const bookmarks      = '/bookmarks';
  static const settings       = '/settings';
}