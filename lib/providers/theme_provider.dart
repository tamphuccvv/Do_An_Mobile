// lib/providers/theme_provider.dart
// Tính năng 4: Dark Mode  |  Tính năng 6: Cỡ chữ & Font

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

enum AppFontFamily { serif, sansSerif }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode      = ThemeMode.light;
  double    _fontSize  = 15.0;          // base content font size
  AppFontFamily _font  = AppFontFamily.serif;

  ThemeMode     get mode     => _mode;
  double        get fontSize => _fontSize;
  AppFontFamily get font     => _font;
  bool get isDark            => _mode == ThemeMode.dark;

  // ── Tải từ SharedPreferences ──────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getBool('darkMode') ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
    _fontSize = prefs.getDouble('fontSize') ?? 15.0;
    _font = (prefs.getString('font') == 'sansSerif')
        ? AppFontFamily.sansSerif
        : AppFontFamily.serif;
    notifyListeners();
  }

  // ── Toggle Dark/Light ─────────────────────────────────────────
  Future<void> toggleTheme() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
    notifyListeners();
  }

  // ── Tăng/Giảm cỡ chữ ─────────────────────────────────────────
  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 24.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  // ── Đổi font family ───────────────────────────────────────────
  Future<void> setFont(AppFontFamily f) async {
    _font = f;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font', f == AppFontFamily.serif ? 'serif' : 'sansSerif');
    notifyListeners();
  }

  // ── TextStyle cho nội dung bài báo ────────────────────────────
  TextStyle get contentStyle {
    if (_font == AppFontFamily.serif) {
      return GoogleFonts.merriweather(fontSize: _fontSize, height: 1.8);
    }
    return GoogleFonts.roboto(fontSize: _fontSize, height: 1.7);
  }

  // ── ThemeData Light ───────────────────────────────────────────
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.surface,
    ),
    dividerColor: AppColors.divider,
    cardColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textCaption,
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textCaption,
      indicatorColor: AppColors.accent,
    ),
  );

  // ── ThemeData Dark ────────────────────────────────────────────
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkColors.background,
    colorScheme: const ColorScheme.dark(
      primary: DarkColors.accent,
      surface: DarkColors.surface,
    ),
    dividerColor: DarkColors.divider,
    cardColor: DarkColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.surface,
      foregroundColor: DarkColors.textPrimary,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: DarkColors.surface,
      selectedItemColor: DarkColors.accent,
      unselectedItemColor: DarkColors.textCaption,
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData( // <--- Thêm chữ "Data" vào đây
      labelColor: DarkColors.accent, // (Hoặc AppColors.accent ở lightTheme)
      unselectedLabelColor: DarkColors.textCaption,
      indicatorColor: DarkColors.accent,
    ),
  );

  // ── Helpers: màu theo theme hiện tại ─────────────────────────
  Color bg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.background
          : AppColors.background;

  Color surf(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.surface
          : AppColors.surface;

  Color text(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.textPrimary
          : AppColors.textPrimary;

  Color sub(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.textSecondary
          : AppColors.textSecondary;

  Color cap(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.textCaption
          : AppColors.textCaption;

  Color acc(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.accent
          : AppColors.accent;

  Color div(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.divider
          : AppColors.divider;

  Color accLight(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? DarkColors.accentLight
          : AppColors.accentLight;
}