import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/json.dart';
import '../models/stakeholder.dart';

class StakeholderRepository {
  StakeholderRepository(this._dio);

  static const _base = '/stakeholder/protected';
  static const _groups = '$_base/group';

  final Dio _dio;

  Future<List<Stakeholder>> list() async {
    final res = await guardApi(() => _dio.get<List<dynamic>>(_base));
    return parseList(res.data, Stakeholder.fromJson);
  }

  Future<Stakeholder> get(String id) async {
    final res = await guardApi(() => _dio.get<Json>('$_base/$id'));
    return Stakeholder.fromJson(res.data!);
  }

  Future<Stakeholder> create(Stakeholder stakeholder) async {
    final res = await guardApi(
      () => _dio.post<Json>(_base, data: stakeholder.toJson()),
    );
    return Stakeholder.fromJson(res.data!);
  }

  Future<Stakeholder> update(String id, Stakeholder stakeholder) async {
    final res = await guardApi(
      () => _dio.put<Json>('$_base/$id', data: stakeholder.toJson()),
    );
    return Stakeholder.fromJson(res.data!);
  }

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<Json>('$_base/$id'));

  Future<List<StakeholderGroup>> listGroups() async {
    final res = await guardApi(() => _dio.get<List<dynamic>>(_groups));
    return parseList(res.data, StakeholderGroup.fromJson);
  }

  Future<StakeholderGroup> getGroup(String id) async {
    final res = await guardApi(() => _dio.get<Json>('$_groups/$id'));
    return StakeholderGroup.fromJson(res.data!);
  }

  Future<StakeholderGroup> createGroup(StakeholderGroup group) async {
    final res = await guardApi(
      () => _dio.post<Json>(_groups, data: group.toJson()),
    );
    return StakeholderGroup.fromJson(res.data!);
  }

  Future<StakeholderGroup> updateGroup(String id, StakeholderGroup group) async {
    final res = await guardApi(
      () => _dio.put<Json>('$_groups/$id', data: group.toJson()),
    );
    return StakeholderGroup.fromJson(res.data!);
  }

  Future<void> deleteGroup(String id) =>
      guardApi(() => _dio.delete<Json>('$_groups/$id'));
}
