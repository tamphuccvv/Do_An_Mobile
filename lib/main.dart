// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/article_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const NewsFlowApp());
}

class NewsFlowApp extends StatelessWidget {
  const NewsFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash:         (_) => const _SplashGate(),
            AppRoutes.login:          (_) => const LoginScreen(),
            AppRoutes.register:       (_) => const RegisterScreen(),
            AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
            AppRoutes.home:           (_) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}

// ── Splash Gate ───────────────────────────────────────────────────
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Chờ providers init xong (auth check session Firebase)
    await Future.delayed(const Duration(milliseconds: 800));

    // ⚠️ Bỏ NotificationService ở đây để tránh timeout block splash
    // FCM sẽ được init sau khi vào HomeScreen
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: theme.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                color: theme.text(context),
              ),
            ),
            Container(
              width: 60, height: 3,
              color: AppColors.accent,
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),
            Text(
              AppStrings.tagline,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.cap(context),
                  letterSpacing: 2),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
                strokeWidth: 2, color: theme.acc(context)),
          ],
        ),
      ),
    );
  }
}