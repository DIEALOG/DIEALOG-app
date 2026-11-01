import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/confirmer_access.dart';
import '../models/json.dart';
import '../models/stakeholder.dart';
import '../models/transition_confirmer.dart';
import '../models/transition_policy.dart';
import '../models/transition_case.dart';
import '../models/alive_check.dart';
import '../models/account_handling_task.dart';
import '../models/designating_user.dart';

class TransitionRepository {
  TransitionRepository(this._dio);

  static const _base = '/transition/protected/confirmers';
  static const _policy = '/transition/protected/policy';
  static const _cases = '/transition/protected/cases';
  static const _checks = '/transition/protected/alive-checks';
  final Dio _dio;

  Future<List<TransitionConfirmer>> listConfirmers() async {
    final response = await guardApi(() => _dio.get<List<dynamic>>(_base));
    return parseList(response.data, TransitionConfirmer.fromJson);
  }

  Future<TransitionInvitation> invite(Stakeholder person) async {
    final response = await guardApi(
      () => _dio.post<Json>(
        _base,
        data: compact({
          'stakeholder_id': person.id,
          'name': person.name,
          'email': person.email,
          'phone': person.phone,
        }),
      ),
    );
    return TransitionInvitation.fromJson(response.data!);
  }

  Future<void> revoke(String id) async {
    await guardApi(() => _dio.delete<Json>('$_base/$id'));
  }

  Future<TransitionInvitation> resend(String id) async {
    final response = await guardApi(() => _dio.post<Json>('$_base/$id/resend'));
    return TransitionInvitation.fromJson(response.data!);
  }

  Future<TransitionPolicy> fetchPolicy() async {
    try {
      final response = await guardApi(() => _dio.get<Json>(_policy));
      return TransitionPolicy.fromJson(response.data!);
    } on ApiException catch (e) {
      if (e.isNotFound) return const TransitionPolicy();
      rethrow;
    }
  }

  /// Only the fields given are sent; the rest keep their stored value.
  Future<TransitionPolicy> updatePolicy({
    int? aliveCheckIntervalDays,
    int? minimumConfirmers,
    int? waitingPeriodDays,
  }) async {
    final response = await guardApi(
      () => _dio.patch<Json>(
        _policy,
        data: compact({
          'alive_check_interval_days': aliveCheckIntervalDays,
          'minimum_confirmers': minimumConfirmers,
          'waiting_period_days': waitingPeriodDays,
        }),
      ),
    );
    return TransitionPolicy.fromJson(response.data!);
  }

  Future<List<TransitionCase>> listCases() async {
    final response = await guardApi(() => _dio.get<List<dynamic>>(_cases));
    return parseList(response.data, TransitionCase.fromJson);
  }

  Future<TransitionCase> getCase(String id) async {
    final response = await guardApi(() => _dio.get<Json>('$_cases/$id'));
    return TransitionCase.fromJson(response.data!);
  }

  Future<TransitionCase> cancelCase(String id) async {
    final response = await guardApi(
      () => _dio.post<Json>('$_cases/$id/cancel'),
    );
    return TransitionCase.fromJson(response.data!);
  }

  Future<List<TransitionConfirmation>> listConfirmations(String caseId) async {
    final response = await guardApi(
      () => _dio.get<List<dynamic>>('$_cases/$caseId/confirmations'),
    );
    return parseList(response.data, TransitionConfirmation.fromJson);
  }

  Future<List<AliveCheck>> listAliveChecks() async {
    final response = await guardApi(() => _dio.get<List<dynamic>>(_checks));
    return parseList(response.data, AliveCheck.fromJson);
  }

  Future<AliveCheck> scheduleAliveCheck() async {
    final response = await guardApi(() => _dio.post<Json>(_checks));
    return AliveCheck.fromJson(response.data!);
  }

  Future<AliveCheck> respondAliveCheck(String id) async {
    final response = await guardApi(
      () => _dio.post<Json>('$_checks/$id/respond'),
    );
    return AliveCheck.fromJson(response.data!);
  }

  Future<List<AccountHandlingTask>> listTasks(String caseId) async {
    final response = await guardApi(
      () => _dio.get<List<dynamic>>('$_cases/$caseId/tasks'),
    );
    return parseList(response.data, AccountHandlingTask.fromJson);
  }

  Future<List<DesignatingUser>> listDesignatingUsers() async {
    final response = await guardApi(
      () => _dio.get<List<dynamic>>(
        '/transition/protected/confirmers/designating-users',
      ),
    );
    return parseList(response.data, DesignatingUser.fromJson);
  }

  /// Issues confirmer auth tokens for invites that match this login.
  /// Missing on older servers (404); callers treat that as "nothing to claim".
  Future<List<ConfirmerAccess>> claimAccess() async {
    final response = await guardApi(
      () => _dio.post<List<dynamic>>(
        '/transition/protected/confirmers/access',
      ),
    );
    return parseList(response.data, ConfirmerAccess.fromJson);
  }

  Future<AccountHandlingRequestResponse> requestTask(String taskId) async {
    final response = await guardApi(
      () => _dio.post<Json>('/transition/protected/tasks/$taskId/request'),
    );
    return AccountHandlingRequestResponse.fromJson(response.data!);
  }
}
