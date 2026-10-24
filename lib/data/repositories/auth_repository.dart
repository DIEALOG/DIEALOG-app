import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_tokens.dart';
import '../models/json.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  static final _public = Options(extra: {AuthInterceptor.skipAuth: true});

  Future<bool> hasSession() async => await _storage.read() != null;

  Future<void> login({required String email, required String password}) =>
      _authenticate('/login', {'email': email, 'password': password});

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) =>
      _authenticate(
        '/signup',
        {'name': name, 'email': email, 'password': password},
      );

  /// The backend has no logout endpoint; dropping the tokens is all we can do.
  Future<void> logout() => _storage.clear();

  Future<void> _authenticate(String path, Json body) async {
    final res = await guardApi(
      () => _dio.post<Json>(path, data: body, options: _public),
    );
    await _storage.write(AuthTokens.fromJson(res.data!));
  }
}
