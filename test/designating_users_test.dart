import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns owners who designated the signed-in user', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final owners = await TransitionRepository(dio).listDesignatingUsers();
    expect(owners, isNotEmpty);
    expect(owners.first.name, '최동훈');
    expect(
      (await TransitionRepository(dio).listConfirmers())
          .any((item) => item.name == '최동훈'),
      isFalse,
    );
    dio.close();
  });
}
