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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedPrivacy = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              const SizedBox(height: 60),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Iconsax.calendar_tick,
                    size: 40,
                    color: AppTheme.primary,
                  ),
                ),
              ).animate().fadeIn().scale().moveY(begin: 20, end: 0),
              
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
              
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Sign in to your Smart ClassCatch',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ).animate().fadeIn(delay: 300.ms).moveY(begin: 10),
              
              const SizedBox(height: 40),
              
              AuthTextField(
                controller: _emailController,
                hintText: 'Student ID or Email',
                icon: Iconsax.user,
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 10),
              
              const SizedBox(height: 20),
              
              AuthTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Iconsax.lock,
                isPassword: true,
              ).animate().fadeIn(delay: 500.ms).moveY(begin: 10),
              
              const SizedBox(height: 12),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.pushNamed('forgot-password'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
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
                  text: 'Sign In',
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
                    ref.read(authProvider.notifier).login(
                      _emailController.text,
                      _passwordController.text,
                    );
                  },
                ).animate().fadeIn(delay: 700.ms).scale(),
              
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.getBorder(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONTINUE WITH',
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
              ).animate().fadeIn(delay: 800.ms),
              
              const SizedBox(height: 32),
              
              const SocialAuthButtons().animate().fadeIn(delay: 900.ms).moveY(begin: 10),
              
              const SizedBox(height: 40),
              
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed('register'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1000.ms),
              
               const SizedBox(height: 20),
               
              
             ],
          ),
        ),
      ),
    );
  }
}
