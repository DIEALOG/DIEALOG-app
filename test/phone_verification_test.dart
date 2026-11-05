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

  test('sends the same E.164 number for SMS and code verification', () async {
    final numbers = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            numbers.add(
              (options.data as Map<String, dynamic>)['phoneNumber'] as String,
            );
            handler.next(options);
          },
        ),
      )
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final verification = PhoneVerificationRepository(dio);

    await verification.sendCode('010-1234-5678');
    await verification.verifyCode('01012345678', '123456');

    expect(numbers, ['+821012345678', '+821012345678']);
  });
}
