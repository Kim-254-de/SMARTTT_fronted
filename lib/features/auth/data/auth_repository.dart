import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  static const String _cachedUserKey = 'cached_user_profile';

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post('auth/login/', data: {
        'email': email,
        'password': password,
      });

      await _storeTokens(response.data);
      final userData = _extractUserData(response.data);
      final user = UserModel.fromJson(userData);
      await _storeUser(user);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Registers a new student.
  /// Backend only requires: email, password, full_name, university_id (optional).
  /// Course/department/year_of_study are NOT part of registration — they belong
  /// to a separate student profile that can be filled in later via the Profile screen.
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? universityId,
  }) async {
    try {
      final response = await apiClient.dio.post('auth/register/', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (universityId != null && universityId.isNotEmpty)
          'admission_number': universityId,
      });

      await _storeTokens(response.data);
      final userData = _extractUserData(response.data);
      final user = UserModel.fromJson(userData);
      await _storeUser(user);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post('auth/password/reset/', data: {'email': email});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await apiClient.dio.post('auth/password/reset/confirm/', data: {
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove(_cachedUserKey);
  }

  /// Deletes (deactivates) the current user's account. Requires their
  /// current password to confirm. On success, clears local tokens too —
  /// the backend has already blacklisted them, but this keeps client
  /// state in sync immediately.
  Future<void> deleteAccount(String password) async {
    try {
      await apiClient.dio.post('auth/account/delete/', data: {
        'password': password,
      });
      await logout();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> fetchProfile() async {
    try {
      final response = await apiClient.dio.get('auth/profile/');
      final user = UserModel.fromJson(_extractUserData(response.data));
      await _storeUser(user);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? admissionNumber,
    String? course,
    String? department,
    int? yearOfStudy,
  }) async {
    try {
      final response = await apiClient.dio.patch('auth/profile/', data: {
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (admissionNumber != null) 'admission_number': admissionNumber,
        if (course != null) 'course': course,
        if (department != null) 'department': department,
        if (yearOfStudy != null) 'year_of_study': yearOfStudy,
      });
      final user = UserModel.fromJson(_extractUserData(response.data));
      await _storeUser(user);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedUserKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _storeTokens(dynamic data) async {
    if (data is! Map) return;
    final access = data['access'];
    final refresh = data['refresh'];
    final prefs = await SharedPreferences.getInstance();
    if (access != null) await prefs.setString('auth_token', access.toString());
    if (refresh != null) await prefs.setString('refresh_token', refresh.toString());
  }

  /// Extracts the user map from `{ "access": "...", "refresh": "...", "user": {...} }`
  /// or a bare user map (used by /auth/profile/).
  Map<String, dynamic> _extractUserData(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final user = map['user'];
      if (user is Map) return Map<String, dynamic>.from(user);
      if (map.containsKey('id') || map.containsKey('email')) return map;
    }
    throw Exception('Invalid user response format');
  }

  /// Converts DioException server errors into readable Exception messages.
  Exception _handleError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      if (data is Map && data.isNotEmpty) {
        if (data.containsKey('detail')) return Exception(data['detail'].toString());
        if (data.containsKey('message')) return Exception(data['message'].toString());
        final first = data.values.first;
        if (first is List && first.isNotEmpty) return Exception(first.first.toString());
        return Exception('Please check the information you entered and try again.');
      }
      if (statusCode != null) {
        if (statusCode >= 500) {
          return Exception('The server is temporarily unavailable. Please try again later.');
        } else if (statusCode == 400) {
          return Exception('Please check the information you entered and try again.');
        } else if (statusCode == 401) {
          final isLogin = e.requestOptions.path.contains('auth/login');
          return Exception(
            isLogin
                ? 'The email or password is incorrect.'
                : 'Your session has expired. Please sign in again.',
          );
        } else if (statusCode == 403) {
          return Exception('You do not have permission to perform this action.');
        } else if (statusCode == 404) {
          return Exception('We could not find what you requested. Please try again.');
        }
      }
      if (e.type == DioExceptionType.connectionError) {
        return Exception('Unable to reach the server. Please check your connection and try again.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('The request took too long. Please try again.');
      }
      return Exception('Something went wrong. Please try again.');
    }
    if (e is Exception) return e;
    return Exception(e.toString());
  }
}
