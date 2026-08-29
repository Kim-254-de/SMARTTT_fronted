import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Base URL ───────────────────────────────────────────────────────────────
// Switch between environments here. Production always uses HTTPS.
const String _baseUrl = 'https://api.nextup.co.ke/api/v1/';
//const String _baseUrl = 'http://localhost:8000/api/v1/';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      // Render free-tier can take ~30 s to cold-start; keep timeouts generous.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    dio.interceptors.add(
      InterceptorsWrapper(
        // ── Attach access token to every request (except auth endpoints) ──
        onRequest: (options, handler) async {
          final isPublic = options.path.contains('auth/login') ||
              options.path.contains('auth/register') ||
              options.path.contains('auth/token/refresh') ||
              options.path.contains('auth/password/reset');

          if (!isPublic) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },

        // ── On 401: silently refresh and retry the original request ────────
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');

            if (refreshToken != null) {
              try {
                // Use a bare Dio instance so this call skips our own interceptor
                final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
                final refreshResponse = await refreshDio.post(
                  'auth/token/refresh/',
                  data: {'refresh': refreshToken},
                );

                final newAccess = refreshResponse.data['access'] as String?;
                if (newAccess != null) {
                  await prefs.setString('auth_token', newAccess);

                  // Retry the original request with the new token
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccess';
                  final retried = await dio.fetch(retryOptions);
                  return handler.resolve(retried);
                }
              } catch (_) {
                // Refresh failed → clear tokens; the UI should navigate to login
                await prefs.remove('auth_token');
                await prefs.remove('refresh_token');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}

final apiClient = ApiClient();
