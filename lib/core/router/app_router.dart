import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/terms_screen.dart';
import '../../features/profile/presentation/screens/privacy_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/schedule/presentation/portal_sync_screen.dart';
import '../../features/schedule/presentation/manual_sync_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';

/// A [ChangeNotifier] that listens to [AuthNotifier] and triggers
/// GoRouter to re-evaluate redirects whenever auth state changes.
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}

/// Provider for the router notifier so we can pass Ref to it.
final authRouterNotifierProvider = Provider((ref) => AuthRouterNotifier(ref));

/// Provider for the GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});

GoRouter createRouter(Ref ref) {
  final notifier = ref.read(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/schedule',
        name: 'schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/portal-sync',
        name: 'portal-sync',
        builder: (context, state) => const PortalSyncScreen(),
      ),
      GoRoute(
        path: '/manual-sync',
        name: 'manual-sync',
        builder: (context, state) => const ManualSyncScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthEntry = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isPublicPolicyPage = state.matchedLocation == '/terms' ||
          state.matchedLocation == '/privacy';

      // Still initializing (loading with no user yet)
      if (authState.isLoading) return null;

      final isAuthenticated = authState.user != null;

      if (!isAuthenticated) {
        if (!isAuthEntry && !isPublicPolicyPage) return '/login';
        return null;
      } else {
        if (isAuthEntry) return '/home';
      }
      return null;
    },
  );
}
