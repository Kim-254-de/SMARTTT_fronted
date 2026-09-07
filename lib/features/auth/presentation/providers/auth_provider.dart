import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_model.dart';
import '../../../notifications/services/fcm_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

String _extractErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      return data['detail']?.toString() ??
          data['message']?.toString() ??
          data.values.first.toString();
    }
    return e.message ?? 'Network error. Please try again.';
  }
  final msg = e.toString();
  return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(isLoading: true);
  }

  Future<void> checkAuth() async {
    final repository = ref.read(authRepositoryProvider);
    state = state.copyWith(isLoading: true, clearError: true);

    // Immediately restore cached user if available (offline-first)
    final cachedUser = await repository.getCachedUser();
    if (cachedUser != null) {
      state = AuthState(user: cachedUser, isLoading: false);
    }

    try {
      final user = await repository.fetchProfile();
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      // Keep cached user if offline or network error
      if (cachedUser != null) {
        state = AuthState(user: cachedUser, isLoading: false);
      } else {
        state = AuthState(isLoading: false);
      }
    }
  }

  Future<void> login(String email, String password) async {
    final repository = ref.read(authRepositoryProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await repository.login(email, password);
      state = AuthState(user: user, isLoading: false);
      Future.microtask(() => FCMService.registerToken());
    } catch (e) {
      state = AuthState(isLoading: false, error: _extractErrorMessage(e));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? universityId,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    Future.microtask(() => FCMService.registerToken());
    try {
      final user = await repository.register(
        fullName: fullName,
        email: email,
        password: password,
        universityId: universityId,
      );
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: _extractErrorMessage(e));
    }
  }

  /// Called after a successful Google sign-in — skips the repository
  /// since token storage and API call are handled in SocialAuthButtons.
  void setUserFromGoogle(UserModel user) {
    state = AuthState(user: user, isLoading: false);
    Future.microtask(() => FCMService.registerToken());
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = AuthState();
  }

  /// Deletes (deactivates) the current account. Throws on failure (e.g.
  /// wrong password) so the calling screen can show the error — on
  /// success, resets state to logged-out same as logout().
  Future<void> deleteAccount(String password) async {
    final repository = ref.read(authRepositoryProvider);
    await repository.deleteAccount(password);
    state = AuthState();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e), isLoading: false);
    }
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
