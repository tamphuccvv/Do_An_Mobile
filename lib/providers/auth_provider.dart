// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user    => _user;
  bool       get loading => _loading;
  String?    get error   => _error;
  bool       get isLoggedIn => _user != null;
  bool       get isAdmin    => _user?.isAdmin ?? false;

  void _setLoading(bool v)  { _loading = v; notifyListeners(); }
  void _setError(String? v) { _error   = v; notifyListeners(); }

  // ── Init: kiểm tra session ────────────────────────────────────
  Future<void> init() async {
    try {
      final firebaseUser = _service.currentUser;
      if (firebaseUser != null) {
        // Timeout 5s để tránh treo splash nếu Firestore chậm
        _user = await _service.getUserData(firebaseUser.uid)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider init error: \$e');
    }
  }

  // ── ĐĂNG KÝ ─────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _user = await _service.register(
          email: email, password: password, username: username);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ── ĐĂNG NHẬP ────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _user = await _service.login(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ── ĐĂNG XUẤT ────────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  // ── QUÊN MẬT KHẨU ────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.forgotPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ── CẬP NHẬT PROFILE ─────────────────────────────────────────
  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _service.updateProfile(
          uid: _user!.id, username: username, avatarUrl: avatarUrl);
      _user = _user!.copyWith(username: username, avatarUrl: avatarUrl);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() => _setError(null);
}