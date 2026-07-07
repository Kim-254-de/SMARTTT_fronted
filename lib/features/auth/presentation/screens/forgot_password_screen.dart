import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/premium_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
              
              const AuthTextField(
                hintText: 'Student Email',
                icon: Iconsax.sms,
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
              
              const SizedBox(height: 32),
              
              PremiumButton(
                text: 'Send Reset Link',
                onPressed: () {
                  // Show success dialog or snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recovery link sent to your email!'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
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
