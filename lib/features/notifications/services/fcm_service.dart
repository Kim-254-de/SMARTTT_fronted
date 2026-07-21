import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class FCMService {
  static final _messaging = FirebaseMessaging.instance;

  /// Call on login — requests permission and registers token with backend
  static Future<void> registerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('push_notifications_enabled') ?? true;
    if (!enabled) return;

    // Request permission (iOS / web)
    await _messaging.requestPermission();

    final token = await _messaging.getToken();
    if (token == null) return;

    await _sendToken(token, 'android');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) => _sendToken(newToken, 'android'));
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
