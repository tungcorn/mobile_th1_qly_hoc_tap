import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebaseBootstrap.dart';
import 'supabaseBootstrap.dart';

/// Thông báo hiển thị trong ứng dụng (từ FCM foreground hoặc Supabase Realtime).
class AppNotification {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  AppNotification({
    required this.title,
    required this.body,
    this.data = const {},
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}

/// Handler nền cho Android (phải là hàm top-level).
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  // Hệ thống tự hiển thị notification payload; không cần xử lý thêm.
}

class NotificationService {
  /// VAPID key (Web Push) — truyền bằng --dart-define=FIREBASE_VAPID_KEY=...
  static const _vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  static String? fcmToken;
  static String? lastError;
  static String status = 'Chưa khởi tạo';

  static final List<AppNotification> history = [];
  static final ValueNotifier<int> unread = ValueNotifier<int>(0);

  static final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();
  static RealtimeChannel? _userChannel;
  static String? _listeningUserId;
  static final Map<String, RealtimeChannel> _sendChannels = {};

  static Stream<AppNotification> get stream => _controller.stream;

  static void markAllRead() => unread.value = 0;

  static void _push(AppNotification n) {
    history.insert(0, n);
    if (history.length > 50) history.removeRange(50, history.length);
    unread.value = unread.value + 1;
    if (!_controller.isClosed) _controller.add(n);
  }

  static Future<void> initialize() async {
    if (!FirebaseBootstrap.isReady || !FirebaseBootstrap.platformSupported) {
      status = 'Bỏ qua: Firebase chưa sẵn sàng hoặc nền tảng không hỗ trợ';
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(notificationBackgroundHandler);
      }
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        status = 'Người dùng từ chối quyền thông báo';
        return;
      }
      fcmToken = await messaging.getToken(
        vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null,
      );
      messaging.onTokenRefresh.listen(
        (token) => fcmToken = token,
        onError: (Object e) => lastError = e.toString(),
      );
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        _push(AppNotification(
          title: n?.title ?? message.data['title']?.toString() ?? 'Thông báo',
          body: n?.body ?? message.data['body']?.toString() ?? '',
          data: Map<String, dynamic>.from(message.data),
        ));
      }, onError: (Object e) => lastError = e.toString());
      status = fcmToken == null ? 'Chưa có FCM token' : 'Đã sẵn sàng';
    } catch (e) {
      lastError = e.toString();
      status = 'Lỗi khởi tạo thông báo';
    }
  }

  static Future<void> listenForUser(String userId) async {
    if (!SupabaseBootstrap.isReady) return;
    try {
      if (_listeningUserId == userId && _userChannel != null) return;
      final old = _userChannel;
      _userChannel = null;
      _listeningUserId = null;
      if (old != null) {
        await Supabase.instance.client.removeChannel(old);
      }
      _userChannel = Supabase.instance.client
          .channel('notify:$userId')
          .onBroadcast(
            event: 'notify',
            callback: (payload) {
              try {
                _push(AppNotification(
                  title: payload['title']?.toString() ?? 'Thông báo',
                  body: payload['body']?.toString() ?? '',
                  data: payload['data'] is Map
                      ? Map<String, dynamic>.from(payload['data'] as Map)
                      : const {},
                ));
              } catch (e) {
                lastError = e.toString();
              }
            },
          )
          .subscribe();
      _listeningUserId = userId;
    } catch (e) {
      lastError = e.toString();
    }
  }

  static Future<void> sendToUser(
    String userId, {
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (!SupabaseBootstrap.isReady) return;
    final payload = {'title': title, 'body': body, 'data': data};
    try {
      final client = Supabase.instance.client;
      RealtimeChannel? channel =
          _listeningUserId == userId ? _userChannel : _sendChannels[userId];
      if (channel == null) {
        final created = client.channel('notify:$userId');
        final ready = Completer<void>();
        created.subscribe((status, [error]) {
          if (!ready.isCompleted &&
              (status == RealtimeSubscribeStatus.subscribed ||
                  status == RealtimeSubscribeStatus.channelError ||
                  status == RealtimeSubscribeStatus.timedOut)) {
            ready.complete();
          }
        });
        await ready.future.timeout(const Duration(seconds: 2));
        _sendChannels[userId] = created;
        channel = created;
      }
      await channel.sendBroadcastMessage(event: 'notify', payload: payload);
    } catch (e) {
      lastError = e.toString();
    }
    try {
      await Supabase.instance.client.functions
          .invoke('send-fcm', body: {'userId': userId, ...payload})
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Best-effort: edge function có thể chưa được deploy.
    }
  }
}
