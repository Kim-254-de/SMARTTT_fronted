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

    final data = error.response?.data;
    final serverMessage = _extractServerMessage(data);
    if (serverMessage != null) {
      final normalized = serverMessage.toLowerCase();
      if (normalized.contains('credential') ||
          normalized.contains('password') ||
          normalized.contains('admission number')) {
        return 'The portal admission number or password is incorrect.';
      }
      if (normalized.contains('no registered') ||
          normalized.contains('units are available') ||
          normalized.contains('units found')) {
        return 'No registered units are available for this semester. '
            'Please confirm your units are registered on the portal.';
      }
      return serverMessage;
    }
  }

  return fallbackMessage;
}

String? _extractServerMessage(dynamic data) {
  if (data is String && data.trim().isNotEmpty) return data.trim();
  if (data is! Map) return null;

  for (final key in ['detail', 'message', 'error']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.isNotEmpty) return value.first.toString();
  }

  return null;
}
