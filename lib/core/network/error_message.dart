import 'package:dio/dio.dart';

String parseErrorMessage(
  dynamic error, {
  String fallbackMessage = 'Something went wrong',
}) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.message?.contains('XMLHttpRequest') == true) {
      return 'Unable to reach the server. Please check your connection and try again.';
    }

    if (error.response?.statusCode == 400) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      return 'Invalid portal credentials or no registered units found.';
    }
  }

  return fallbackMessage;
}