import 'package:dio/dio.dart';

class ErrorMessageHelper {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet connection.';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Your session has expired. Please log in again.';
          } else if (statusCode == 403) {
            return 'You do not have permission to view this schedule.';
          } else if (statusCode == 404) {
            return 'No schedule found for the current term.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server is currently unavailable. Please try again later.';
          }
          return 'Unable to load schedule. Please try again.';

        case DioExceptionType.connectionError:
          return 'No internet connection. Please verify your network.';

        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please refresh.';
  }
}
