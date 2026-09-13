import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/premium_button.dart';
import '../providers/auth_provider.dart';

/// The very first screen a visitor sees at nextup.co.ke — lets them pick
/// Student or Lecturer before going to Login. The choice is stored in
/// [selectedRoleProvider] purely to preselect the right tab on Register and
/// to adjust Login's heading; the backend still determines the real role
/// from whichever account actually logs in.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  void _choose(BuildContext context, WidgetRef ref, String role) {
    ref.read(selectedRoleProvider.notifier).state = role;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Iconsax.calendar_tick, size: 46, color: AppTheme.primary),
                ),
              ).animate().fadeIn().scale().moveY(begin: 20, end: 0),

              const SizedBox(height: 28),
              Text(
                'SMART ClassCatch',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn(delay: 150.ms).moveY(begin: 10),

              const SizedBox(height: 8),
              Text(
                'How would you like to continue?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 250.ms).moveY(begin: 10),

              const SizedBox(height: 48),

              _RoleCard(
                icon: Iconsax.user,
                title: 'Continue as Student',
                subtitle: 'View your timetable and class updates',
                onTap: () => _choose(context, ref, 'student'),
              ).animate().fadeIn(delay: 350.ms).moveY(begin: 12),

              const SizedBox(height: 16),

              _RoleCard(
                icon: Iconsax.profile_circle,
                title: 'Continue as Lecturer',
                subtitle: 'Manage your teaching schedule and notify students',
                onTap: () => _choose(context, ref, 'lecturer'),
              ).animate().fadeIn(delay: 450.ms).moveY(begin: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.getTextSecondary(context), size: 14),
          ],
        ),
      ),
    );
  }
}