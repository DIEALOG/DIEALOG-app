import 'package:diealog_app/core/network/api_exception.dart';
import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/repositories/phone_verification_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PhoneVerificationRepository repo() {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    return PhoneVerificationRepository(dio);
  }

  test('verify fails until a code has been sent', () async {
    final verification = repo();
    await expectLater(
      verification.verifyCode('010-1234-5678', '123456'),
      throwsA(isA<ApiException>()),
    );
  });

  test('accepts a six-digit code after send', () async {
    final verification = repo();
    await verification.sendCode('010-1234-5678');
    expect(await verification.verifyCode('010-1234-5678', '123456'), isTrue);
    await expectLater(
      verification.verifyCode('010-1234-5678', '123456'),
      throwsA(isA<ApiException>()),
    );
  });
}
