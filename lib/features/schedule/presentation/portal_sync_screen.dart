import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/premium_button.dart';
import 'providers/timetable_provider.dart';

/// Lets the student sync their registered units from the Tharaka University
/// student portal. The student's portal username + password are sent ONCE
/// to our backend, which logs in server-side, scrapes the registered units,
/// saves them, and discards the credentials immediately — they are never
/// stored anywhere, client or server.
class PortalSyncScreen extends ConsumerStatefulWidget {
  const PortalSyncScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PortalSyncScreen> createState() => _PortalSyncScreenState();
}

class _PortalSyncScreenState extends ConsumerState<PortalSyncScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(timetableProvider.notifier);
    final success = await notifier.syncFromPortal(
      portalUsername: _usernameController.text.trim(),
      portalPassword: _passwordController.text,
    );

    // Credentials are cleared from the form immediately after the request,
    // regardless of outcome — they should never linger in memory.
    _passwordController.clear();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units synced successfully!')),
      );
      context.pop();
    } else {
      final error = ref.read(timetableProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Sync failed. Please check your credentials.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: AppTheme.getTextPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Sync with Portal',
          style: TextStyle(
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.shield_tick, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your portal password is used once to fetch your '
                        'registered units, then discarded immediately. '
                        'We never store it.',
                        style: TextStyle(
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Portal Admission Number',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'e.g. TUN/CS/001/2023',
                  prefixIcon: const Icon(Iconsax.hashtag),
                  filled: true,
                  fillColor: AppTheme.getSurface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Portal Password',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Portal password',
                  prefixIcon: const Icon(Iconsax.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppTheme.getSurface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                PremiumButton(
                  text: 'Sync Registered Units',
                  onPressed: _submit,
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Iconsax.edit_2, size: 18),
                  label: const Text('Enter units manually instead'),
                  onPressed: () => context.push('/manual-sync'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
