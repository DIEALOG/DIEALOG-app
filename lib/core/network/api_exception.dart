import 'package:dio/dio.dart';

/// Error surfaced to the UI. [message] is always safe to show the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('서버 응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.');
      case DioExceptionType.connectionError:
        return const ApiException('서버에 연결할 수 없어요. 네트워크를 확인해 주세요.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    // 5xx bodies can carry raw server internals (e.g. Go panic text), so
    // never show them.
    if (status != null && status >= 500) {
      return ApiException('서버 오류가 발생했어요.', statusCode: status);
    }
    final data = e.response?.data;
    final message = data is Map && data['message'] is String
        ? data['message'] as String
        : '요청을 처리하지 못했어요.';
    return ApiException(message, statusCode: status);
  }

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  /// Server English leftovers that settings/inbox used to dump as-is.
  String get userMessage {
    final lower = message.toLowerCase();
    if (lower.contains('transition policy not found')) {
      return '전환 정책이 아직 없어요. 잠시 후 다시 시도해 주세요.';
    }
    if (lower.contains('invitation not found') ||
        lower.contains('invitation is no longer active')) {
      return '초대가 만료됐거나 이미 처리됐어요.';
    }
    if (lower.contains('active transition case already exists')) {
      return '이미 진행 중인 전환 요청이 있어요.';
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Runs a Dio call and rethrows transport errors as [ApiException].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
