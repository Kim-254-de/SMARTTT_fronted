import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/domain/notification_model.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationProvider.notifier).fetchNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2,
              color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationProvider.notifier).fetchNotifications(),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.danger, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.read(notificationProvider.notifier).fetchNotifications(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.notification,
              size: 64,
              color: AppTheme.getTextSecondary(context).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Timetable updates and reminders\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              ref
                  .read(notificationProvider.notifier)
                  .markAsRead(notification.id);
            }
            _showNotificationDetail(context, notification);
          },
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).moveY(begin: 10);
      },
    );
  }

  void _showNotificationDetail(
      BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _NotificationIcon(type: notification.notificationType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.getTextPrimary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDate(notification.sentAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              // If it's a timetable/sync notification, show quick action
              if (notification.notificationType == 'timetable_change' ||
                  notification.notificationType == 'sync_reminder')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Iconsax.refresh),
                    label: const Text('Sync Now'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/portal-sync');
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isUnread
            ? AppTheme.primary.withOpacity(0.05)
            : AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? AppTheme.primary.withOpacity(0.2)
              : AppTheme.getBorder(context),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.notificationType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getTextSecondary(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(notification.sentAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getTextSecondary(context).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'timetable_change':
        icon = Iconsax.calendar_edit;
        color = AppTheme.primary;
        break;
      case 'sync_reminder':
        icon = Iconsax.refresh;
        color = AppTheme.accent;
        break;
      case 'registration_reminder':
        icon = Iconsax.book;
        color = AppTheme.success;
        break;
      default:
        icon = Iconsax.notification;
        color = AppTheme.secondary;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
