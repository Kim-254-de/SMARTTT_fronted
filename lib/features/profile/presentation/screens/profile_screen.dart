import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/notifications_provider.dart';
import '../../../notifications/services/fcm_service.dart';
import '../widgets/delete_account_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr('My Profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Profile Header with Edit button below avatar ───────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: const Icon(Iconsax.user, size: 50, color: AppTheme.primary),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.camera, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Student Name',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Text(
                    user?.email ?? 'student@university.edu',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  // Edit Profile button — visible directly below name
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamed('edit-profile'),
                    icon: const Icon(Iconsax.edit, size: 16),
                    label: Text(context.tr('Edit Profile')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 32),

            // ── Academic Info ──────────────────────────────────────────────
            _buildSection(
              context,
              title: context.tr('Academic Information'),
              children: [
                _buildInfoTile(context, Iconsax.book, context.tr('Admission'), user?.universityId ?? 'N/A'),
                _buildInfoTile(context, Iconsax.call, context.tr('Phone'),
                    user?.phoneNumber?.isNotEmpty == true ? user!.phoneNumber! : 'N/A'),
              ],
            ).animate().fadeIn(delay: 100.ms).moveY(begin: 20),

            const SizedBox(height: 24),

            // ── App Preferences ────────────────────────────────────────────
            _buildSection(
              context,
              title: context.tr('App Preferences'),
              children: [
                _buildToggleTile(
                  context,
                  Iconsax.moon,
                  context.tr('Dark Mode'),
                  themeMode == ThemeMode.dark,
                  (val) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                Consumer(
                builder: (context, ref, _) {
                final enabled = ref.watch(notificationsEnabledProvider);
                return _buildToggleTile(
                context,
                Iconsax.notification,
                context.tr('Push Notifications'),
                enabled,
                (val) async {
                await ref.read(notificationsEnabledProvider.notifier).toggle(val);
                if (val) {
                await FCMService.registerToken();
                } else {
                await FCMService.unregisterToken();
        }
      },
    );
  },
),
                // Language selector — shows a bottom sheet with English/Swahili
                _buildLanguageTile(
                  context,
                  currentLocale,
                  (locale) => ref.read(localeProvider.notifier).setLocale(locale),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).moveY(begin: 20),

            const SizedBox(height: 24),

            // ── Support & Feedback ─────────────────────────────────────────
            _buildSection(
              context,
              title: context.tr('Support & Feedback'),
              children: [
                _buildActionTile(context, Iconsax.message_question, context.tr('Contact University Support'), null, () => context.pushNamed('support')),
                _buildActionTile(
                  context,
                  Iconsax.security_user,
                  context.tr('Privacy Policy'),
                  null,
                  () => context.push('/privacy'),
                ),
                _buildActionTile(
                  context,
                  Iconsax.info_circle,
                  context.tr('Terms & Conditions'),
                  null,
                  () => context.push('/terms'),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20),

            const SizedBox(height: 24),

            // ── Account ────────────────────────────────────────────────────
            _buildSection(
              context,
              title: context.tr('Account'),
              children: [
                _buildActionTile(context, Iconsax.lock, context.tr('Change Password'), null, () {}),
                _buildActionTile(
                  context,
                  Iconsax.trash,
                  context.tr('Delete Account'),
                  null,
                  () async {
                    final deleted = await showDeleteAccountDialog(context);
                    if (deleted == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('Your account has been deleted.'))),
                      );
                      context.go('/login');
                    }
                  },
                  isDestructive: true,
                ),
                _buildActionTile(
                  context,
                  Iconsax.logout,
                  context.tr('Logout'),
                  null,
                  () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  isDestructive: true,
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 20),

            const SizedBox(height: 32),

            Center(
              child: Column(
                children: [
                  Text('Smart ClassCatch v1.0.0',
                      style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('tharaka.ac.ke',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, Locale current, Function(Locale) onSelect) {
    final langLabel = current.languageCode == 'sw' ? 'Kiswahili' : 'English';
    return InkWell(
      onTap: () => _showLanguagePicker(context, current, onSelect),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Iconsax.translate, size: 20, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.tr('Language'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text(langLabel, style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right_3, size: 14, color: AppTheme.getTextSecondary(context).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, Locale current, Function(Locale) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _languageOption(ctx, 'English', 'en', current, onSelect),
              const Divider(),
              _languageOption(ctx, 'Kiswahili', 'sw', current, onSelect),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(
    BuildContext context,
    String label,
    String code,
    Locale current,
    Function(Locale) onSelect,
  ) {
    final isSelected = current.languageCode == code;
    return InkWell(
      onTap: () {
        onSelect(Locale(code));
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : AppTheme.getTextPrimary(context),
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.getTextSecondary(context))),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.getBorder(context)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context))),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(BuildContext context, IconData icon, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.getTextSecondary(context)),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String label, String? value, VoidCallback onTap,
      {bool isDestructive = false}) {
    final color = isDestructive ? AppTheme.error : AppTheme.getTextPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDestructive ? color : AppTheme.getTextSecondary(context)),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color))),
            if (value != null) Text(value, style: TextStyle(fontSize: 14, color: AppTheme.getTextSecondary(context))),
            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right_3, size: 14, color: AppTheme.getTextSecondary(context).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
