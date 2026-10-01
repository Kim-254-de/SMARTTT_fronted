import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/premium_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/network/error_message.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email address.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (mounted) _showMessage('If an account exists, a recovery link has been sent.');
    } catch (error) {
      if (mounted) _showMessage(friendlyErrorMessage(error, fallbackMessage: 'Could not send the recovery link. Please try again.'));
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
                onPressed: () => context.pop(),
                icon: Icon(Iconsax.arrow_left_2, color: AppTheme.getTextPrimary(context)),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.getSurface(context),
                  padding: const EdgeInsets.all(12),
                  side: BorderSide(color: AppTheme.getBorder(context)),
                ),
              ),
              
              const SizedBox(height: 40),
              Text(
                'Reset Password',
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn().moveX(begin: -20),
              
              const SizedBox(height: 8),
              Text(
                'Enter your student email to receive a recovery link',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 100.ms).moveX(begin: -20),
              
              const SizedBox(height: 40),
              
              AuthTextField(
                hintText: 'Student Email',
                icon: Iconsax.sms,
                controller: _emailController,
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
              
              const SizedBox(height: 32),
              
              PremiumButton(
                text: _isSubmitting ? 'Sending...' : 'Send Reset Link',
                onPressed: _isSubmitting ? () {} : _submit,
              ).animate().fadeIn(delay: 300.ms).scale(),
              
              const SizedBox(height: 40),
              
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Remember password? Sign In',
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
