import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post('auth/login/', data: {
        'email': email,
        'password': password,
      });

      await _storeTokens(response.data);
      final userData = _extractUserData(response.data);
      return UserModel.fromJson(userData);
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
          'university_id': universityId,
      });

      await _storeTokens(response.data);
      final userData = _extractUserData(response.data);
      return UserModel.fromJson(userData);
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
  }

  Future<UserModel> fetchProfile() async {
    try {
      final response = await apiClient.dio.get('auth/profile/');
      return UserModel.fromJson(_extractUserData(response.data));
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiClient.dio.patch('auth/profile/', data: {
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      return UserModel.fromJson(_extractUserData(response.data));
    } catch (e) {
      throw _handleError(e);
    }
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
        return Exception(data.toString());
      }
      if (statusCode != null) {
        if (statusCode >= 500) {
          return Exception('Server error ($statusCode). Please try again later.');
        } else if (statusCode == 400) {
          return Exception('Bad request (400). Please check your input.');
        } else if (statusCode == 403) {
          return Exception('Access denied (403).');
        } else if (statusCode == 404) {
          return Exception('Endpoint not found (404).');
        }
      }
      return Exception(e.message ?? 'Network error. Please try again.');
    }
    if (e is Exception) return e;
    return Exception(e.toString());
  }
}
