import 'dart:convert';
import 'dart:typed_data';

import 'package:diealog_app/core/network/auth_interceptor.dart';
import 'package:diealog_app/core/storage/token_storage.dart';
import 'package:diealog_app/data/models/auth_tokens.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _old = AuthTokens(accessToken: 'old', refreshToken: 'r-old');

void main() {
  late InMemoryTokenStorage storage;
  late Dio dio;
  late _FakeAdapter api;
  late _FakeAdapter refreshApi;
  late int expiredCalls;

  /// Protected endpoints accept only the refreshed token.
  Future<ResponseBody> protectedApi(RequestOptions o) async =>
      o.headers['Authorization'] == 'Bearer new'
          ? _json(200, {'ok': true})
          : _json(401, {'message': 'expired'});

  void setUpDio({
    required Future<ResponseBody> Function(RequestOptions) onRefresh,
  }) {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    api = _FakeAdapter(protectedApi);
    refreshApi = _FakeAdapter(onRefresh);
    dio.httpClientAdapter = api;
    refreshDio.httpClientAdapter = refreshApi;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        storage: storage,
        onSessionExpired: () => expiredCalls++,
      ),
    );
  }

  setUp(() {
    storage = InMemoryTokenStorage(_old);
    expiredCalls = 0;
  });

  test('skipAuth requests carry no Authorization header', () async {
    setUpDio(onRefresh: (_) async => _json(500, {}));
    api = _FakeAdapter((_) async => _json(200, {}));
    dio.httpClientAdapter = api;

    await dio.get<void>(
      '/login',
      options: Options(extra: {AuthInterceptor.skipAuth: true}),
    );

    expect(api.requests.single.headers['Authorization'], isNull);
  });

  test('refreshes once for concurrent 401s and retries both', () async {
    setUpDio(
      onRefresh: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _json(200, {'accessToken': 'new', 'refreshToken': 'r-new'});
      },
    );

    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/a'),
      dio.get<Map<String, dynamic>>('/b'),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(refreshApi.requests, hasLength(1));
    expect(refreshApi.requests.single.data, {'refreshToken': 'r-old'});
    expect((await storage.read())!.accessToken, 'new');
    expect(expiredCalls, 0);
  });

  test('a rejected refresh token clears the session', () async {
    setUpDio(onRefresh: (_) async => _json(401, {'message': 'invalid'}));

    await expectLater(
      dio.get<void>('/a'),
      throwsA(
        isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 401),
      ),
    );

    expect(await storage.read(), isNull);
    expect(expiredCalls, 1);
  });

  test('a network failure during refresh keeps the session', () async {
    setUpDio(
      onRefresh: (o) async => throw DioException.connectionError(
        requestOptions: o,
        reason: 'offline',
      ),
    );

    await expectLater(dio.get<void>('/a'), throwsA(isA<DioException>()));

    expect((await storage.read())!.accessToken, 'old');
    expect(expiredCalls, 0);
  });
}
