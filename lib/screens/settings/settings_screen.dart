// lib/screens/settings/settings_screen.dart
// Tính năng 4: Dark Mode  |  Tính năng 6: Cỡ chữ & Font  |  TTS speed

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bg    = theme.bg(context);
    final surf  = theme.surf(context);
    final txt   = theme.text(context);
    final sub   = theme.sub(context);
    final div   = theme.div(context);
    final acc   = theme.acc(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surf,
        iconTheme: IconThemeData(color: txt),
        title: Text('Cài đặt',
            style: GoogleFonts.playfairDisplay(
                color: txt, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ══════════════════════════════════════════════════════
          // GIAO DIỆN
          // ══════════════════════════════════════════════════════
          _SectionHeader(title: 'GIAO DIỆN', color: sub),

          // Dark Mode
          _SettingsTile(
            surf: surf,
            div: div,
            icon: theme.isDark ? Icons.dark_mode : Icons.light_mode,
            iconColor: acc,
            title: 'Chế độ tối',
            subtitle: theme.isDark ? 'Đang bật' : 'Đang tắt',
            trailing: Switch(
              value: theme.isDark,
              activeColor: acc,
              onChanged: (_) => theme.toggleTheme(),
            ),
          ),

          // Preview font
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.all(14),
            color: surf,
            child: Text(
              'Xem trước: Đây là đoạn văn mẫu để bạn thử cỡ chữ và font. '
              'Nhà nước và nhân dân cùng chung tay xây dựng đất nước.',
              style: theme.contentStyle.copyWith(color: txt),
            ),
          ),

          // ══════════════════════════════════════════════════════
          // CỠ CHỮ
          // ══════════════════════════════════════════════════════
          _SectionHeader(title: 'CỠ CHỮ BÀI BÁO', color: sub),

          Container(
            color: surf,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('A',
                        style: GoogleFonts.merriweather(
                            fontSize: 12, color: sub)),
                    Expanded(
                      child: Slider(
                        value: theme.fontSize,
                        min: 12,
                        max: 24,
                        divisions: 6,
                        activeColor: acc,
                        inactiveColor: div,
                        onChanged: (v) => theme.setFontSize(v),
                      ),
                    ),
                    Text('A',
                        style: GoogleFonts.merriweather(
                            fontSize: 22, color: sub)),
                  ],
                ),
                Text('${theme.fontSize.toStringAsFixed(0)}pt',
                    style: GoogleFonts.roboto(color: sub, fontSize: 12)),
              ],
            ),
          ),
          Divider(height: 1, color: div),

          // ══════════════════════════════════════════════════════
          // FONT FAMILY
          // ══════════════════════════════════════════════════════
          _SectionHeader(title: 'KIỂU CHỮ', color: sub),

          _FontOption(
            surf: surf, div: div, txt: txt, sub: sub, acc: acc,
            label: 'Serif (Merriweather)',
            subtitle: 'Phong cách báo chí truyền thống',
            style: GoogleFonts.merriweather(fontSize: 14, color: txt),
            selected: theme.font == AppFontFamily.serif,
            onTap: () => theme.setFont(AppFontFamily.serif),
          ),
          _FontOption(
            surf: surf, div: div, txt: txt, sub: sub, acc: acc,
            label: 'Sans-serif (Roboto)',
            subtitle: 'Hiện đại, dễ đọc trên màn hình',
            style: GoogleFonts.roboto(fontSize: 14, color: txt),
            selected: theme.font == AppFontFamily.sansSerif,
            onTap: () => theme.setFont(AppFontFamily.sansSerif),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Tiêu đề section ──────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color  color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title,
          style: GoogleFonts.robotoCondensed(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: color)),
    );
  }
}

// ── Settings tile chung ──────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final Color surf, div, iconColor;
  final IconData icon;
  final String title, subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.surf, required this.div,
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      color: surf,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: iconColor, size: 22),
            title: Text(title,
                style: GoogleFonts.roboto(
                    color: theme.text(context),
                    fontWeight: FontWeight.w500)),
            subtitle: Text(subtitle,
                style: GoogleFonts.roboto(
                    color: theme.cap(context), fontSize: 12)),
            trailing: trailing,
          ),
          Divider(height: 1, color: div),
        ],
      ),
    );
  }
}

// ── Lựa chọn font ────────────────────────────────────────────────
class _FontOption extends StatelessWidget {
  final Color surf, div, txt, sub, acc;
  final String label, subtitle;
  final TextStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _FontOption({
    required this.surf, required this.div,
    required this.txt, required this.sub, required this.acc,
    required this.label, required this.subtitle,
    required this.style, required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: surf,
        child: Column(
          children: [
            ListTile(
              title: Text(label, style: style),
              subtitle: Text(subtitle,
                  style: GoogleFonts.roboto(color: sub, fontSize: 12)),
              trailing: selected
                  ? Icon(Icons.check_circle, color: acc, size: 22)
                  : Icon(Icons.radio_button_unchecked,
                      color: sub, size: 22),
            ),
            Divider(height: 1, color: div),
          ],
        ),
      ),
    );
  }
}
