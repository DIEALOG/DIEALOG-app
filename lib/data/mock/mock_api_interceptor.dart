import 'package:dio/dio.dart';

import 'mock_backend.dart';

/// Answers every request from [MockBackend] instead of the network.
///
/// Installed while the server is unreachable (see `Env.useMockApi`); the
/// repositories above it are unchanged, so removing the interceptor is all it
/// takes to go live.
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor({MockBackend? backend, this.latency = _defaultLatency})
    : backend = backend ?? MockBackend.seeded();

  static const _defaultLatency = Duration(milliseconds: 220);

  final MockBackend backend;
  final Duration latency;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(latency);
    try {
      final result = backend.handle(
        options.method,
        options.path,
        options.data,
        headers: options.headers,
      );
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: result.status,
          data: result.data,
        ),
      );
    } on MockApiError catch (e) {
      handler.reject(
        DioException.badResponse(
          statusCode: e.status,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: e.status,
            data: {'message': e.message},
          ),
        ),
      );
    }
  }
}
