// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/editorial_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.login(email: _emailCtrl.text, password: _passCtrl.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Masthead
                Text(AppStrings.appName,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 42, fontWeight: FontWeight.w900,
                        color: theme.text(context), letterSpacing: -1)),
                Container(height: 3, width: 60, color: theme.acc(context),
                    margin: const EdgeInsets.symmetric(vertical: 8)),
                Text(AppStrings.tagline,
                    style: GoogleFonts.robotoCondensed(
                        fontSize: 13, color: theme.sub(context), letterSpacing: 2)),
                const SizedBox(height: 48),
                Text(AppStrings.login,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: theme.text(context))),
                const SizedBox(height: 24),

                // Error
                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: theme.accLight(context),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: theme.acc(context), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.error!,
                          style: GoogleFonts.roboto(color: theme.acc(context), fontSize: 13))),
                    ]),
                  ),

                EditorialField(
                  controller: _emailCtrl,
                  label: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                ),
                const SizedBox(height: 16),

                EditorialField(
                  controller: _passCtrl,
                  label: AppStrings.password,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                        color: theme.cap(context), size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: Text(AppStrings.forgotPassword,
                        style: GoogleFonts.roboto(color: theme.acc(context), fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.acc(context),
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(), elevation: 0),
                    child: auth.loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppStrings.login,
                            style: GoogleFonts.robotoCondensed(
                                fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Chưa có tài khoản? ',
                      style: GoogleFonts.roboto(color: theme.sub(context), fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text(AppStrings.register,
                        style: GoogleFonts.roboto(
                            color: theme.acc(context), fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
