
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/network/error_message.dart';
 
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({super.key});
 
  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}
 
class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  bool _isLoading = false;
 
 

Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);

  try {
    UserCredential userCredential;

    if (kIsWeb) {
      // Web: use Firebase's own popup flow — no google_sign_in package needed
      final googleProvider = GoogleAuthProvider();
      userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      // Mobile: keep using google_sign_in
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    // Get Firebase ID token for our Django backend
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('Google sign-in failed. Please try again.');

    // Send to Django — get our own JWT back
    final response = await apiClient.dio.post(
      'auth/google/',
      data: {'id_token': idToken},
    );

    final data = response.data as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['access'] as String);
    await prefs.setString('refresh_token', data['refresh'] as String);

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    ref.read(authProvider.notifier).setUserFromGoogle(user);

    if (mounted) context.go('/home');
  } on FirebaseAuthException catch (e) {
    // Closing the Google popup is a normal choice, not an error.
    if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') return;
    if (mounted) {
      final msg = e.code == 'popup-blocked'
          ? 'Your browser blocked the Google sign-in window. Allow pop-ups for this site and try again.'
          : e.code == 'network-request-failed'
              ? 'Unable to reach Google. Please check your internet connection and try again.'
              : 'Google sign-in failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
      );
    }
  } catch (e) {
    if (mounted) {
      final msg = friendlyErrorMessage(e, fallbackMessage: 'Google sign-in failed. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
 
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: CircularProgressIndicator(),
            ),
          )
        : Column(
            children: [
              _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onTap: _handleGoogleSignIn,
              ),
              const SizedBox(height: 12),
              // Google can create a new account, which skips the sign-up checkboxes.
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _consentText(context, 'By continuing with Google you agree to our '),
                  _consentLink(context, 'Terms & Conditions', 'terms'),
                  _consentText(context, ' and '),
                  _consentLink(context, 'Privacy Policy', 'privacy'),
                  _consentText(context, '.'),
                ],
              ),
            ],
          );
  }

  Widget _consentText(BuildContext context, String text) => Text(
        text,
        style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
      );

  Widget _consentLink(BuildContext context, String text, String routeName) => InkWell(
        onTap: () => context.pushNamed(routeName),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.primary,
          ),
        ),
      );
}
 
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
 
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final textStyleColor = AppTheme.getTextPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textStyleColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textStyleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
