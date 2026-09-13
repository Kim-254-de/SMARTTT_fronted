import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/lecturer_dashboard_model.dart';

/// Thrown when a venue-change notification fails the room-capacity check.
/// [suggestedRooms] is populated by the backend so the UI can offer
/// alternatives instead of a dead-end error message.
class VenueCapacityException implements Exception {
  final String message;
  final List<Map<String, dynamic>> suggestedRooms;
  VenueCapacityException(this.message, this.suggestedRooms);
}

class LecturerRepository {
  /// GET /auth/lecturer/profile/ — single call that feeds Home, Schedule
  /// and Profile. See apps/accounts/views/auth_views.py::LecturerProfileView.
  Future<LecturerDashboardModel> fetchDashboard() async {
    try {
      final response = await apiClient.dio.get('auth/lecturer/profile/');
      return LecturerDashboardModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /notifications/lecturer/validate-venue/
  /// Call this before send() when notificationType == 'venue_change' so the
  /// lecturer gets instant capacity feedback (with alternatives) rather than
  /// discovering it only after tapping Send.
  Future<void> validateVenue({
    required String newVenueId,
    required int expectedStudents,
  }) async {
    try {
      await apiClient.dio.post('notifications/lecturer/validate-venue/', data: {
        'new_venue_id': newVenueId,
        'expected_students': expectedStudents,
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('capacity_error')) {
        final suggestions = (data['suggested_rooms'] as List? ?? [])
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        throw VenueCapacityException(data['capacity_error'].toString(), suggestions);
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /notifications/lecturer/send/
  /// For notificationType == 'venue_change', pass newVenueId + expectedStudents
  /// too — the backend re-validates capacity and only sends if it fits.
  Future<Map<String, dynamic>> sendNotification({
    required String unitId,
    required String notificationType,
    required String title,
    required String message,
    String? newVenueId,
    int? expectedStudents,
  }) async {
    try {
      final response = await apiClient.dio.post('notifications/lecturer/send/', data: {
        'unit_id': unitId,
        'notification_type': notificationType,
        'title': title,
        'message': message,
        if (newVenueId != null) 'new_venue_id': newVenueId,
        if (expectedStudents != null) 'expected_students': expectedStudents,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('capacity_error')) {
        final suggestions = (data['suggested_rooms'] as List? ?? [])
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        throw VenueCapacityException(data['capacity_error'].toString(), suggestions);
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /rooms/rooms/?search=... — used by the venue picker when
  /// notificationType == 'venue_change'.
  Future<List<RoomModel>> fetchRooms({String? search}) async {
    try {
      final response = await apiClient.dio.get('rooms/rooms/', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final dynamic data = response.data;
      final List<dynamic> results = data is Map && data['results'] is List
          ? data['results'] as List
          : (data is List ? data : []);
      return results.map((json) => RoomModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.isNotEmpty) {
        if (data.containsKey('detail')) return Exception(data['detail'].toString());
        final first = data.values.first;
        if (first is List && first.isNotEmpty) return Exception(first.first.toString());
      }
      final statusCode = e.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return Exception('The server is temporarily unavailable. Please try again later.');
      }
      return Exception('Something went wrong. Please try again.');
    }
    return Exception('Something went wrong. Please try again.');
  }
}
