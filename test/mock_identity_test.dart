import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/repositories/profile_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
  });

  tearDown(() => dio.close());

  test('seeded session stays the demo persona', () async {
    final profile = await ProfileRepository(dio).fetch();
    expect(profile.name, '김서연');
    expect(await StakeholderRepository(dio).list(), isNotEmpty);
  });

  test('login as another email drops the seeded persona', () async {
    await dio.post<void>(
      '/login',
      data: {'email': 'me@example.com', 'password': 'secret'},
    );
    final profile = await ProfileRepository(dio).fetch();
    expect(profile.email, 'me@example.com');
    expect(profile.name, isNot('김서연'));
    expect(await StakeholderRepository(dio).list(), isEmpty);
  });

  test('signup replaces seeded data with the new account', () async {
    await dio.post<void>(
      '/signup',
      data: {
        'name': '박민준',
        'email': 'minjun@example.com',
        'password': 'secret',
        'phone_number': '01011112222',
      },
    );
    final profile = await ProfileRepository(dio).fetch();
    expect(profile.name, '박민준');
    expect(profile.email, 'minjun@example.com');
    expect(await StakeholderRepository(dio).list(), isEmpty);
  });
}
