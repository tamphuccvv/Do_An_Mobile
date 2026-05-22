// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── ĐĂNG KÝ  (POST /api/auth/register) ──────────────────────
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(username);

      final model = UserModel(
        id: cred.user!.uid,
        username: username.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(model.id).set(model.toMap());
      return model;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ── ĐĂNG NHẬP  (POST /api/auth/login) ───────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final model = await getUserData(cred.user!.uid);
      return model!;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ── ĐĂNG XUẤT ───────────────────────────────────────────────
  Future<void> logout() => _auth.signOut();

  // ── QUÊN MẬT KHẨU ───────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ── LẤY THÔNG TIN USER ──────────────────────────────────────
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  // ── CẬP NHẬT PROFILE ────────────────────────────────────────
  Future<void> updateProfile({
    required String uid,
    String? username,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) {
      updates['username'] = username;
      await _auth.currentUser?.updateDisplayName(username);
    }
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  // ── XỬ LÝ LỖI FIREBASE ──────────────────────────────────────
  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':   return 'Email đã được dùng.';
      case 'invalid-email':          return 'Email không hợp lệ.';
      case 'weak-password':          return 'Mật khẩu tối thiểu 6 ký tự.';
      case 'user-not-found':         return 'Không tìm thấy tài khoản.';
      case 'wrong-password':         return 'Sai mật khẩu.';
      case 'too-many-requests':      return 'Thử quá nhiều lần. Thử lại sau.';
      case 'network-request-failed': return 'Lỗi kết nối mạng.';
      default: return e.message ?? 'Đã có lỗi xảy ra.';
    }
  }
}