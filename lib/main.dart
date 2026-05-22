// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'providers/auth_provider.dart';
import 'providers/article_provider.dart';
import 'utils/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()), // THÊM DÒNG NÀY
      ],
      child: const NewsFlowApp(),
    ),
  );
}

class NewsFlowApp extends StatelessWidget {
  const NewsFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gọi ThemeProvider ra để lắng nghe thay đổi
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      // CẤU HÌNH THEME Ở ĐÂY
      themeMode: themeProvider.mode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,

      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
      },
    );
  }
}