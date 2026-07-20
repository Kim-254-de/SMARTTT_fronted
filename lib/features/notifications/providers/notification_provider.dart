import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

class NotificationState {
  final bool isLoading;
  final String? error;
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository());

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => fetchNotifications());
    return NotificationState();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final notifications = await repo.fetchMyNotifications();
      final unread = notifications.where((n) => !n.isRead).length;
      state = NotificationState(
        notifications: notifications,
        unreadCount: unread,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(notificationId);
      final updated = state.notifications.map((n) {
        return n.id == notificationId ? n.copyWith(isRead: true) : n;
      }).toList();
      final unread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final unread = state.notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markAsRead(n.id);
    }
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        NotificationNotifier.new);
