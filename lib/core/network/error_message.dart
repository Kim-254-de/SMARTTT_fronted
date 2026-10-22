import 'package:dio/dio.dart';

const String _genericMessage = 'Something went wrong. Please try again.';
const String _offlineMessage =
    'Unable to reach the server. Please check your internet connection and try again.';

/// Turns any error (network, server or app) into a short sentence a user can
/// act on. Server messages are shown when they are already written for users
/// (e.g. "A user with this email already exists."); stack traces, exception
/// class names, HTML error pages and other developer text are never shown.
String friendlyErrorMessage(
  Object? error, {
  String fallbackMessage = _genericMessage,
}) {
  if (error is DioException) return _fromDio(error, fallbackMessage);

  if (error is Exception || error is String) {
    final text = error
        .toString()
        .replaceFirst(RegExp(r'^\w*Exception:\s*'), '')
        .trim();
    if (_isUserFacing(text)) return text;
  }

  return fallbackMessage;
}

/// Timetable portal-sync flavour of [friendlyErrorMessage]: the portal's own
/// credential and "no units" errors get portal-specific wording.
String parseErrorMessage(
  dynamic error, {
  String fallbackMessage = _genericMessage,
}) {
  if (error is DioException) {
    final serverMessage = _extractServerMessage(error.response?.data);
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
    }
  }

  return friendlyErrorMessage(error, fallbackMessage: fallbackMessage);
}

String _fromDio(DioException e, String fallback) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'The server is taking too long to respond. Please try again.';
    case DioExceptionType.connectionError:
      return _offlineMessage;
    case DioExceptionType.badCertificate:
      return 'A secure connection to the server could not be made. Please try again later.';
    case DioExceptionType.cancel:
      return 'The request was cancelled. Please try again.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final status = e.response?.statusCode;
  // On web a blocked or failed request surfaces as an XMLHttpRequest error
  // with no response at all.
  if (status == null) return _offlineMessage;

  if (status >= 500) {
    return 'The server is having a problem right now. Please try again in a few minutes.';
  }

  final path = e.requestOptions.path;
  final serverMessage = _extractServerMessage(e.response?.data);
  final usable = serverMessage != null && _isUserFacing(serverMessage);

  if (status == 401) {
    if (path.contains('auth/login')) {
      if (usable && !_isGenericCredentialMessage(serverMessage)) return serverMessage;
      return 'The email/ID or password you entered is incorrect.';
    }
    return 'Your session has expired. Please sign in again.';
  }

  if (usable) return serverMessage;

  switch (status) {
    case 400:
      return 'Some of the information you entered is not valid. Please check it and try again.';
    case 403:
      return 'You do not have permission to do this.';
    case 404:
      return 'We could not find what you were looking for. It may have been removed.';
    case 409:
      return 'This clashes with existing information. Please review it and try again.';
    case 413:
      return 'The file is too large to upload.';
    case 429:
      return 'Too many attempts. Please wait a moment and try again.';
  }

  return fallback;
}

bool _isGenericCredentialMessage(String message) {
  final m = message.toLowerCase();
  return m.contains('invalid credentials') || m.contains('no active account');
}

/// Pulls the most relevant message out of a DRF error body:
/// `{"detail": "..."}`, `{"email": ["..."]}`, `{"non_field_errors": ["..."]}`.
String? _extractServerMessage(dynamic data) {
  if (data is String) {
    final text = data.trim();
    return text.isEmpty ? null : text;
  }
  if (data is List && data.isNotEmpty) return _extractServerMessage(data.first);
  if (data is! Map || data.isEmpty) return null;

  for (final key in ['detail', 'message', 'error', 'non_field_errors']) {
    final value = _firstText(data[key]);
    if (value != null) return _sentence(value);
  }

  for (final entry in data.entries) {
    final value = _firstText(entry.value);
    if (value == null) continue;
    // "This field is required." means nothing without the field's name.
    if (RegExp(r'^(this field|ensure this field|this value)', caseSensitive: false).hasMatch(value)) {
      return '${_fieldLabel(entry.key.toString())}: ${_sentence(value)}';
    }
    return _sentence(value);
  }
  return null;
}

String? _firstText(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is List && value.isNotEmpty) return _firstText(value.first);
  if (value is Map && value.isNotEmpty) return _firstText(value.values.first);
  return null;
}

String _sentence(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

String _fieldLabel(String key) {
  final words = key.replaceAll('_', ' ').trim();
  return words.isEmpty ? 'This field' : _sentence(words);
}

final RegExp _developerText = RegExp(
  r'exception|traceback|stack ?trace|xmlhttprequest|socket|dioerror|'
  r"type '|subtype|null check|instance of|status code|requestoptions|"
  r'\bpk\b|uuid|object does not exist|invalid .* response format|id token|'
  r'<[a-z!/]',
  caseSensitive: false,
);

bool _isUserFacing(String text) =>
    text.isNotEmpty && text.length <= 200 && !_developerText.hasMatch(text);
