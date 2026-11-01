import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_interceptor.dart';
import '../models/json.dart';
import 'mock/verification_repository.dart';

class PhoneVerificationRepository implements VerificationRepository {
  PhoneVerificationRepository(this._dio);

  final Dio _dio;

  Options get _public => Options(extra: {AuthInterceptor.skipAuth: true});

  @override
  Future<void> sendCode(String phone) => guardApi(
    () => _dio.post<Json>(
      '/phone-verification/send',
      data: {'phoneNumber': phone},
      options: _public,
    ),
  );

  @override
  Future<bool> verifyCode(String phone, String code) async {
    await guardApi(
      () => _dio.post<Json>(
        '/phone-verification/verify',
        data: {'phoneNumber': phone, 'code': code},
        options: _public,
      ),
    );
    return true;
  }
}
