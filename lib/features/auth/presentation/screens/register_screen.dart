import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/premium_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _admissionController = TextEditingController();
  bool _acceptedPrivacy = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _admissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

     ref.listen(authProvider, (previous, next) {
       if (next.error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
         );
       }
       if (next.user != null) {
         context.go('/home');
       }
     });

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
                'Create Account',
                style: Theme.of(context).textTheme.displayLarge,
              ).animate().fadeIn().moveX(begin: -20),
              
              const SizedBox(height: 8),
              Text(
                'Join the Smart Timetable Community',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 100.ms).moveX(begin: -20),
              
              const SizedBox(height: 40),
              
              AuthTextField(
                controller: _nameController,
                hintText: 'Full Name',
                icon: Iconsax.user,
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
              
              const SizedBox(height: 20),
              
              AuthTextField(
                controller: _admissionController,
                hintText: 'Admission Number',
                icon: Iconsax.hashtag,
              ).animate().fadeIn(delay: 250.ms).moveY(begin: 10),
              
              const SizedBox(height: 20),
              
              AuthTextField(
                controller: _emailController,
                hintText: 'Student Email',
                icon: Iconsax.sms,
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 10),
              
              const SizedBox(height: 20),
              
              AuthTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Iconsax.lock,
                isPassword: true,
              ).animate().fadeIn(delay: 450.ms).moveY(begin: 10),
              
              const SizedBox(height: 20),
              
              AuthTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                icon: Iconsax.lock_1,
                isPassword: true,
              ).animate().fadeIn(delay: 500.ms).moveY(begin: 10),
              
              const SizedBox(height: 32),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedPrivacy,
                activeColor: AppTheme.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'I agree to the ',
                      style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                    ),
                    InkWell(
                      onTap: () => context.pushNamed('privacy'),
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                onChanged: (value) => setState(() => _acceptedPrivacy = value ?? false),
                dense: true,
                side: BorderSide(color: AppTheme.getBorder(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),

              const SizedBox(height: 8),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedTerms,
                activeColor: AppTheme.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'I agree to the ',
                      style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                    ),
                    InkWell(
                      onTap: () => context.pushNamed('terms'),
                      child: Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                dense: true,
                side: BorderSide(color: AppTheme.getBorder(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),

              const SizedBox(height: 12),
              
              if (authState.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                PremiumButton(
                  text: 'Create Account',
                  onPressed: () {
                    if (!_acceptedPrivacy || !_acceptedTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please accept both the Privacy Policy and Terms & Conditions first.'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                      return;
                    }
                    if (_passwordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.error),
                      );
                      return;
                    }
                    ref.read(authProvider.notifier).register(
                      fullName: _nameController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                      universityId: _admissionController.text,
                    );
                  },
                ).animate().fadeIn(delay: 600.ms).scale(),
              
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.getBorder(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR REGISTER WITH',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondary(context),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.getBorder(context))),
                ],
              ).animate().fadeIn(delay: 700.ms),
              
              const SizedBox(height: 32),
              
              const SocialAuthButtons().animate().fadeIn(delay: 800.ms).moveY(begin: 10),
              
              const SizedBox(height: 40),
              
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 900.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
