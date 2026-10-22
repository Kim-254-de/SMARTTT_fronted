import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/lecturer_dashboard_provider.dart';
import 'package:smart/core/theme/app_theme.dart';
import 'package:smart/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart/core/theme/notifications_provider.dart';
import 'package:smart/features/profile/presentation/widgets/change_password_link.dart';
import 'package:smart/widgets/theme_cycle_button.dart';
import '../widgets/lecturer_colors.dart';

/// Same order as the attendance profile pages: who you are, your details, settings,
/// then Sign out last. The theme is the app-bar button, not a switch in the list.
class LecturerProfileTab extends ConsumerWidget {
  const LecturerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturerInfo = ref.watch(lecturerDashboardProvider).dashboard?.lecturer;
    final user = ref.watch(authProvider).user;
    final rank = lecturerInfo?.rank.isNotEmpty == true ? lecturerInfo!.rank : 'Lecturer';
    final department = lecturerInfo?.department.isNotEmpty == true ? lecturerInfo!.department : null;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        title: const Text('Staff Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.getTextPrimary(context),
        centerTitle: false,
        actions: const [ThemeCycleButton(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            context,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: LecturerColors.navyBg,
                    child: Icon(Icons.person_outline, size: 36, color: LecturerColors.navy),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName : 'Lecturer',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          department == null ? rank : '$rank · $department',
                          style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            child: Column(
              children: [
                _infoTile(context, Icons.badge_outlined, 'Staff ID', lecturerInfo?.staffId.isNotEmpty == true ? lecturerInfo!.staffId : 'Not recorded'),
                if (user != null) _infoTile(context, Icons.mail_outline, 'Email', user.email),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Security'),
          _settingTile(
            context,
            icon: Icons.key_outlined,
            title: 'Change Password',
            subtitle: 'We email you a link to choose a new one',
            onTap: user == null ? null : () => sendChangePasswordLink(context, ref, user.email),
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Alerts'),
          _card(
            context,
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: LecturerColors.navy),
              title: Text('Timetable Change Alerts',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
              subtitle: Text('Receive instant notifications for rescheduled classes',
                  style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
              value: ref.watch(notificationsEnabledProvider),
              activeThumbColor: LecturerColors.navy,
              onChanged: (val) => ref.read(notificationsEnabledProvider.notifier).toggle(val),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Support'),
          _settingTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Timetable Administrator Helpdesk',
            subtitle: 'Report scheduling conflicts or venue clashes',
            onTap: () => context.push('/support'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                // Back to the role selection screen.
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.getTextSecondary(context))),
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context))),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.getTextPrimary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return _card(
      context,
      child: ListTile(
        leading: Icon(icon, color: LecturerColors.navy),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
