// lib/services/notification_service.dart
// Tính năng 7: Thông báo Đẩy (FCM + Local Notifications)

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Top-level handler cho background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  // Firebase đã được init từ main.dart
}

class NotificationService {
  final FirebaseMessaging            _fcm   = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore            _db    = FirebaseFirestore.instance;

  // ── Init (gọi 1 lần trong main) ───────────────────────────────
  Future<void> init(String? userId) async {
    // Xin quyền
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Cấu hình local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Tạo notification channel (Android 8+)
    await _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'newsflow_high',
        'Breaking News',
        description: 'Thông báo tin tức nóng',
        importance: Importance.high,
      ));

    // Lưu FCM token vào Firestore
    if (userId != null) await _saveToken(userId);

    // Foreground: hiển thị local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }

  // ── Lưu token FCM vào Firestore (để server gửi targeted push) ─
  Future<void> _saveToken(String userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    // Refresh token tự động
    _fcm.onTokenRefresh.listen((newToken) {
      _db.collection('users').doc(userId)
          .update({'fcmToken': newToken});
    });
  }

  // ── Hiển thị Local Notification khi app đang foreground ───────
  Future<void> _showLocalNotification(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;

    await _local.show(
      msg.hashCode,
      n.title ?? 'NewsFlow',
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'newsflow_high',
          'Breaking News',
          channelDescription: 'Thông báo tin tức nóng',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: msg.data['articleId'],
    );
  }

  // ── Xử lý tap vào notification ────────────────────────────────
  void _onTap(NotificationResponse res) {
    // articleId nằm trong res.payload
    // Navigator sẽ được xử lý trong main.dart qua GlobalKey
  }

  // ── Subscribe/Unsubscribe topic (Breaking News) ───────────────
  Future<void> subscribeBreakingNews()   async =>
      _fcm.subscribeToTopic('breaking_news');

  Future<void> unsubscribeBreakingNews() async =>
      _fcm.unsubscribeFromTopic('breaking_news');

  // ── Lấy initial message (app mở từ terminated bởi notification)
  Future<RemoteMessage?> getInitialMessage() =>
      _fcm.getInitialMessage();
}
