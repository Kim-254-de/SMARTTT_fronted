
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
    if (idToken == null) throw Exception('Could not get ID token from Google.');

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
  } catch (e) {
    if (mounted) {
      final msg = e.toString().replaceFirst('Exception: ', '');
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
        : _SocialButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onTap: _handleGoogleSignIn,
          );
  }
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
 
