// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/editorial_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure      = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.register(
        email: _emailCtrl.text, password: _passCtrl.text, username: _nameCtrl.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg(context),
      appBar: AppBar(
        backgroundColor: theme.surf(context),
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text(context)),
        title: Text(AppStrings.register,
            style: GoogleFonts.playfairDisplay(
                color: theme.text(context), fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auth.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: theme.accLight(context),
                  child: Text(auth.error!,
                      style: GoogleFonts.roboto(color: theme.acc(context), fontSize: 13)),
                ),

              EditorialField(
                controller: _nameCtrl, label: AppStrings.username,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên của bạn' : null,
              ),
              const SizedBox(height: 16),
              EditorialField(
                controller: _emailCtrl, label: AppStrings.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
              ),
              const SizedBox(height: 16),
              EditorialField(
                controller: _passCtrl, label: AppStrings.password,
                obscure: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: theme.cap(context), size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
              ),
              const SizedBox(height: 16),
              EditorialField(
                controller: _confirmCtrl, label: 'Xác nhận mật khẩu',
                obscure: _obscure,
                validator: (v) => v != _passCtrl.text ? 'Mật khẩu không khớp' : null,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.acc(context),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(), elevation: 0),
                  child: auth.loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppStrings.register,
                          style: GoogleFonts.robotoCondensed(
                              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
