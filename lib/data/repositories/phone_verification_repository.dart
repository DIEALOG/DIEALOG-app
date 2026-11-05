import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_interceptor.dart';
import '../models/json.dart';
import 'mock/verification_repository.dart';

class PhoneVerificationRepository implements VerificationRepository {
  PhoneVerificationRepository(this._dio);

  final Dio _dio;

  Options get _public => Options(extra: {AuthInterceptor.skipAuth: true});

  // The SMS API expects E.164, while signup stores Korean domestic numbers.
  String _verificationNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^01[016789]\d{7,8}$').hasMatch(digits)) {
      throw const ApiException('올바른 휴대폰 번호를 입력해 주세요.');
    }
    return '+82${digits.substring(1)}';
  }

  @override
  Future<void> sendCode(String phone) => guardApi(
    () => _dio.post<Json>(
      '/phone-verification/send',
      data: {'phoneNumber': _verificationNumber(phone)},
      options: _public,
    ),
  );

  @override
  Future<bool> verifyCode(String phone, String code) async {
    await guardApi(
      () => _dio.post<Json>(
        '/phone-verification/verify',
        data: {'phoneNumber': _verificationNumber(phone), 'code': code},
        options: _public,
      ),
    );
    return true;
  }
}
