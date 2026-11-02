import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'api_constants.dart';

/// Dio client with auth interceptor.
///
/// - Adds `Authorization: Bearer <access_token>` to every request.
/// - On 401: refresh once and retry; if refresh fails, sign out to the gate.
class ApiClient {
  final Dio dio;
  final AuthNotifier _authNotifier;

  ApiClient(this._authNotifier)
      : dio = Dio(BaseOptions(
          baseUrl: ApiConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    dio.interceptors.add(_AuthInterceptor(_authNotifier));
  }
}

class _AuthInterceptor extends Interceptor {
  final AuthNotifier _authNotifier;
  bool _isRefreshing = false;

  _AuthInterceptor(this._authNotifier);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authNotifier.getValidAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final success = await _authNotifier.refreshToken();
        if (success) {
          // Retry the original request with new token
          final token = await _authNotifier.getValidAccessToken();
          if (token != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await Dio().fetch(err.requestOptions);
            _isRefreshing = false;
            return handler.resolve(response);
          }
        }
      } catch (_) {
        // Refresh failed
      }

      _isRefreshing = false;
      await _authNotifier.signOut();
    }

    handler.next(err);
  }
}

/// Provider for the API client
final apiClientProvider = Provider<ApiClient>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return ApiClient(authNotifier);
});
