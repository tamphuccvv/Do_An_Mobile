// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/constants.dart';
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
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
        email: _emailCtrl.text, password: _passCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Masthead ────────────────────────────────────
                Text(AppStrings.appName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    )),
                Container(height: 3, width: 60, color: AppColors.accent,
                    margin: const EdgeInsets.symmetric(vertical: 8)),
                Text(AppStrings.tagline,
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    )),

                const SizedBox(height: 48),
                Text(AppStrings.login,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 24),

                // ── Error ───────────────────────────────────────
                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: AppColors.accentLight,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(auth.error!,
                              style: GoogleFonts.roboto(
                                  color: AppColors.accent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // ── Email ───────────────────────────────────────
                EditorialField(
                  controller: _emailCtrl,
                  label: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                ),
                const SizedBox(height: 16),

                // ── Password ────────────────────────────────────
                EditorialField(
                  controller: _passCtrl,
                  label: AppStrings.password,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textCaption, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                  (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: Text(AppStrings.forgotPassword,
                        style: GoogleFonts.roboto(
                            color: AppColors.accent, fontSize: 13)),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Button đăng nhập ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                    ),
                    child: auth.loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : Text(AppStrings.login,
                        style: GoogleFonts.robotoCondensed(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản? ',
                        style: GoogleFonts.roboto(
                            color: AppColors.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: Text(AppStrings.register,
                          style: GoogleFonts.roboto(
                              color: AppColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Editorial text field ─────────────────────────────────────────
class EditorialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const EditorialField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.merriweather(
          fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(
            color: AppColors.textCaption, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.divider)),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.accent, width: 2)),
        errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.accent)),
        suffixIcon: suffixIcon,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}