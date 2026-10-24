import 'package:dio/dio.dart';

import '../../data/models/auth_tokens.dart';
import '../storage/token_storage.dart';

/// Attaches the bearer token and, on 401, refreshes it once and retries.
///
/// Concurrent 401s share a single `/refresh` call. A request that failed with
/// a token which has since been replaced is retried without refreshing again.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.refreshDio,
    required this.storage,
    this.onSessionExpired,
  });

  /// Set `extra: {AuthInterceptor.skipAuth: true}` on public endpoints.
  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  final Dio dio;
  final Dio refreshDio;
  final TokenStorage storage;
  final void Function()? onSessionExpired;

  Future<String?>? _refreshing;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
      final tokens = await storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = _bearer(tokens.accessToken);
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[skipAuth] == true ||
        options.extra[_retried] == true) {
      handler.next(err);
      return;
    }

    final current = await storage.read();
    final String? token;
    if (current != null &&
        options.headers['Authorization'] != _bearer(current.accessToken)) {
      token = current.accessToken;
    } else {
      token = await _refreshOnce(current);
    }
    if (token == null) {
      handler.next(err);
      return;
    }

    try {
      final retry = await dio.fetch<dynamic>(
        options.copyWith(extra: {...options.extra, _retried: true}),
      );
      handler.resolve(retry);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshOnce(AuthTokens? current) =>
      _refreshing ??= _refresh(current).whenComplete(() => _refreshing = null);

  Future<String?> _refresh(AuthTokens? current) async {
    if (current == null) {
      onSessionExpired?.call();
      return null;
    }
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        '/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final tokens = AuthTokens.fromJson(res.data!);
      await storage.write(tokens);
      return tokens.accessToken;
    } on DioException catch (e) {
      // Only a rejected refresh token ends the session; a network failure
      // keeps it so the next request can try again.
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        await storage.clear();
        onSessionExpired?.call();
      }
      return null;
    }
  }

  static String _bearer(String token) => 'Bearer $token';
}
