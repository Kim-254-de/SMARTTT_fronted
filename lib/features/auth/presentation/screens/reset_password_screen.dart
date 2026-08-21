import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/premium_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirmation = _confirmController.text;
    if (password.isEmpty || confirmation.isEmpty) {
      _showMessage('Enter and confirm your new password.');
      return;
    }
    if (password != confirmation) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            token: widget.token,
            newPassword: password,
            confirmPassword: confirmation,
          );
      if (mounted) {
        _showMessage('Password updated successfully.');
        context.go('/login');
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                onPressed: () => context.go('/login'),
                icon: Icon(Iconsax.arrow_left_2, color: AppTheme.getTextPrimary(context)),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.getSurface(context),
                  padding: const EdgeInsets.all(12),
                  side: BorderSide(color: AppTheme.getBorder(context)),
                ),
              ),
              const SizedBox(height: 40),
              Text('Choose a new password', style: Theme.of(context).textTheme.displayLarge)
                  .animate().fadeIn().moveX(begin: -20),
              const SizedBox(height: 8),
              Text('Your reset link is valid for a limited time.',
                      style: Theme.of(context).textTheme.bodyMedium)
                  .animate().fadeIn(delay: 100.ms).moveX(begin: -20),
              const SizedBox(height: 40),
              AuthTextField(
                hintText: 'New Password',
                icon: Iconsax.lock,
                isPassword: true,
                controller: _passwordController,
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
              const SizedBox(height: 16),
              AuthTextField(
                hintText: 'Confirm Password',
                icon: Iconsax.lock,
                isPassword: true,
                controller: _confirmController,
              ).animate().fadeIn(delay: 250.ms).moveY(begin: 10),
              const SizedBox(height: 32),
              PremiumButton(
                text: _isSubmitting ? 'Updating...' : 'Update Password',
                onPressed: _isSubmitting ? () {} : _submit,
              ).animate().fadeIn(delay: 300.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }
}