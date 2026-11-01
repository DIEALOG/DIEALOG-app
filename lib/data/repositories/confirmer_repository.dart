import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_interceptor.dart';
import '../models/confirmer_access.dart';
import '../models/json.dart';

class ConfirmerRepository {
  const ConfirmerRepository(this._dio);

  final Dio _dio;

  Future<ConfirmerAccess> acceptInvitation(String token) async {
    final response = await guardApi(
      () => _dio.post<Json>(
        '/transition/invitations/accept',
        data: {'token': token},
        options: Options(extra: {AuthInterceptor.skipAuth: true}),
      ),
    );
    return ConfirmerAccess.fromJson(response.data!);
  }

  Future<void> declineInvitation(String token) => guardApi(
    () => _dio.post<Json>(
      '/transition/invitations/decline',
      data: {'token': token},
      options: Options(extra: {AuthInterceptor.skipAuth: true}),
    ),
  );
}
