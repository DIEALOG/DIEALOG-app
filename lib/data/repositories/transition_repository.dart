import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/json.dart';
import '../models/stakeholder.dart';
import '../models/transition_confirmer.dart';
import '../models/transition_policy.dart';

class TransitionRepository {
  TransitionRepository(this._dio);

  static const _base = '/transition/protected/confirmers';
  static const _policy = '/transition/protected/policy';
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
    final response = await guardApi(() => _dio.get<Json>(_policy));
    return TransitionPolicy.fromJson(response.data!);
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
}
