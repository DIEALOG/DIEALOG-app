import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/json.dart';
import '../models/stakeholder.dart';
import '../models/transition_confirmer.dart';

class TransitionRepository {
  TransitionRepository(this._dio);

  static const _base = '/transition/protected/confirmers';
  final Dio _dio;

  Future<List<TransitionConfirmer>> listConfirmers() async {
    final response = await guardApi(() => _dio.get<List<dynamic>>(_base));
    return parseList(response.data, TransitionConfirmer.fromJson);
  }

  Future<TransitionConfirmer> invite(Stakeholder person) async {
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
    return TransitionConfirmer.fromJson(response.data!['confirmer'] as Json);
  }

  Future<void> revoke(String id) async {
    await guardApi(() => _dio.delete<Json>('$_base/$id'));
  }

  Future<void> resend(String id) async {
    await guardApi(() => _dio.post<Json>('$_base/$id/resend'));
  }
}
