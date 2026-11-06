import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_interceptor.dart';
import '../models/confirmer_access.dart';
import '../models/json.dart';
import '../models/transition_case.dart';

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

  Options _confirmerOptions(String authToken) => Options(
    headers: {'X-Confirmer-Token': authToken},
    extra: {AuthInterceptor.skipAuth: true},
  );

  Future<List<TransitionCase>> listCases(String authToken) async {
    final response = await guardApi(
      () => _dio.get<List<dynamic>>(
        '/transition/confirmer/cases',
        options: _confirmerOptions(authToken),
      ),
    );
    return parseList(response.data, TransitionCase.fromJson);
  }

  Future<TransitionCase> startCase(String authToken, {String? reason}) async {
    final response = await guardApi(
      () => _dio.post<Json>(
        '/transition/confirmer/cases',
        data: compact({'reason': reason}),
        options: _confirmerOptions(authToken),
      ),
    );
    return TransitionCase.fromJson(response.data!);
  }

  Future<TransitionCase> getCase(String authToken, String id) async {
    final response = await guardApi(
      () => _dio.get<Json>(
        '/transition/confirmer/cases/$id',
        options: _confirmerOptions(authToken),
      ),
    );
    return TransitionCase.fromJson(response.data!);
  }

  Future<List<TransitionConfirmation>> listConfirmations(
    String authToken,
    String caseId,
  ) async {
    final response = await guardApi(
      () => _dio.get<List<dynamic>>(
        '/transition/confirmer/cases/$caseId/confirmations',
        options: _confirmerOptions(authToken),
      ),
    );
    return parseList(response.data, TransitionConfirmation.fromJson);
  }

  Future<TransitionConfirmation> confirm(
    String authToken,
    String caseId,
    TransitionDecision decision, {
    String? comment,
  }) async {
    final response = await guardApi(
      () => _dio.post<Json>(
        '/transition/confirmer/cases/$caseId/confirmations',
        data: compact({'decision': decision.wire, 'comment': comment}),
        options: _confirmerOptions(authToken),
      ),
    );
    return TransitionConfirmation.fromJson(response.data!);
  }
}
