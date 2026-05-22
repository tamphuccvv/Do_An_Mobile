// lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'login_screen.dart' show EditorialField;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  Future<void> _send() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_emailCtrl.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(AppStrings.forgotPassword,
            style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập email tài khoản của bạn. Chúng tôi sẽ gửi link đặt lại mật khẩu.',
              style: GoogleFonts.merriweather(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),

            if (_sent)
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFECFDF5),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Email đặt lại mật khẩu đã được gửi. Kiểm tra hộp thư của bạn.',
                        style: GoogleFonts.roboto(
                            color: Color(0xFF059669), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (auth.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppColors.accentLight,
                  child: Text(auth.error!,
                      style: GoogleFonts.roboto(
                          color: AppColors.accent, fontSize: 13)),
                ),

              EditorialField(
                controller: _emailCtrl,
                label: AppStrings.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                  ),
                  child: auth.loading
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Text('Gửi email đặt lại',
                      style: GoogleFonts.robotoCondensed(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}