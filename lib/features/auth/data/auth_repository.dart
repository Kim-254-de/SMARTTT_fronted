import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/error_message.dart';
import '../domain/models/department_model.dart';
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

  /// Registers a new lecturer.
  /// Backend validates staff_id against the pre-loaded ValidStaffID list
  /// (uploaded by admin/ICT) — registration fails with a clear message if
  /// the staff ID isn't recognised or has already been claimed.
  Future<UserModel> registerLecturer({
    required String fullName,
    required String email,
    required String staffId,
    required String password,
    required String departmentId,
  }) async {
    try {
      final response = await apiClient.dio.post('auth/lecturer/register/', data: {
        'full_name': fullName,
        'email': email,
        'staff_id': staffId,
        'password': password,
        'department': departmentId,
      });

      await _storeTokens(response.data);
      final userData = _extractUserData(response.data);
      final user = UserModel.fromJson(userData);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /departments/departments/ — public (read-only for unauthenticated
  /// users), used to populate the department picker on lecturer registration.
  Future<List<DepartmentModel>> fetchDepartments() async {
    try {
      final response = await apiClient.dio.get('departments/departments/');
      final dynamic data = response.data;
      final List<dynamic> results = data is Map && data['results'] is List
          ? data['results'] as List
          : (data is List ? data : []);
      return results
          .map((json) => DepartmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// NOTE: Password reset is not yet implemented on the backend.
  /// This will throw a 404 until that endpoint is added.

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

  /// Converts any failure into an Exception carrying a user-friendly message.
  Exception _handleError(Object e) => Exception(friendlyErrorMessage(e));
}
