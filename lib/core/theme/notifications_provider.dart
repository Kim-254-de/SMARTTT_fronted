import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true; // default on
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('push_notifications_enabled') ?? true;
  }

  Future<void> toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', value);
    state = value;
  }
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsNotifier, bool>(NotificationsNotifier.new);
