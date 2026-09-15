import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/lecturer_dashboard_provider.dart';
import 'package:smart/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/lecturer_colors.dart';

class LecturerProfileTab extends ConsumerWidget {
  const LecturerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(lecturerDashboardProvider);
    final lecturerInfo = dashboardState.dashboard?.lecturer;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Staff Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: LecturerColors.navyBg,
                  child: const Icon(Icons.person_outline, size: 36, color: LecturerColors.navy),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff ID: ${lecturerInfo?.staffId ?? 'N/A'}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lecturerInfo?.department ?? 'Department of Computer Science',
                        style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[400] : Colors.grey[650]),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: LecturerColors.navyBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Rank: ${lecturerInfo?.rank ?? 'Lecturer'}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LecturerColors.navy),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'System & Alerts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Timetable Change Alerts',
            subtitle: 'Receive instant notifications for rescheduled classes',
            value: true,
            isDarkMode: isDarkMode,
            onChanged: (val) {},
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme',
            subtitle: 'Toggle app color appearance',
            value: isDarkMode,
            isDarkMode: isDarkMode,
            onChanged: (val) {},
          ),
          const SizedBox(height: 24),
          const Text(
            'Support & Session',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.help_outline_rounded,
            title: 'Timetable Administrator Helpdesk',
            subtitle: 'Report scheduling conflicts or venue clashes',
            isDarkMode: isDarkMode,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Log out of the lecturer portal',
            isDarkMode: isDarkMode,
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              // Trigger logout clearing tokens and resetting auth state
              await ref.read(authProvider.notifier).logout();
              
              if (context.mounted) {
                // Redirect user back to login screen
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? LecturerColors.navy),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? (isDarkMode ? Colors.white : Colors.black87)),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[650]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: LecturerColors.navy),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[650]),
        ),
        value: value,
        activeColor: LecturerColors.navy,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
