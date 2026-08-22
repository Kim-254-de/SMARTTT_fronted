import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _messageEvents = StreamController<RemoteMessage>.broadcast();
  static bool _listenersReady = false;
  static bool _tokenRefreshReady = false;

  static Stream<RemoteMessage> get messageEvents => _messageEvents.stream;

  static Future<void> initialize() async {
    if (_listenersReady) return;
    _listenersReady = true;
    FirebaseMessaging.onMessage.listen(_messageEvents.add);
    FirebaseMessaging.onMessageOpenedApp.listen(_messageEvents.add);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _messageEvents.add(initialMessage);
  }

  /// Call on login — requests permission and registers token with backend
  static Future<void> registerToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('push_notifications_enabled') ?? true;
      if (!enabled) return;

      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token == null) return;

      await _sendToken(token, _platformName());
      if (!_tokenRefreshReady) {
        _tokenRefreshReady = true;
        _messaging.onTokenRefresh.listen(
          (newToken) => _sendToken(newToken, _platformName()),
        );
      }
    } catch (_) {}
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'ios';
      default:
        return 'android';
    }
  }

  /// Call when user disables notifications — removes token from backend
  static Future<void> unregisterToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await apiClient.dio.delete(
        'notifications/unregister-token/',
        data: {'token': token},
      );
    } catch (_) {}
  }

  static Future<void> _sendToken(String token, String platform) async {
    try {
      await apiClient.dio.post('notifications/register-token/', data: {
        'token': token,
        'platform': platform,
      });
    } catch (_) {}
  }
}
