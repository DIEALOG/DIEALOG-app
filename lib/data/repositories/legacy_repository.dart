import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/account.dart';
import '../models/json.dart';
import '../models/legacy.dart';

class LegacyRepository {
  LegacyRepository(this._dio);

  static const _base = '/legacy/protected';

  final Dio _dio;

  /// [page] is assumed to be 1-based; the API reports `offset` back.
  Future<Paginated<Legacy>> list({int page = 1, int limit = 20}) async {
    final res = await guardApi(
      () => _dio.get<Json>(
        _base,
        queryParameters: {'page': page, 'limit': limit},
      ),
    );
    return Paginated.fromJson(res.data!, Legacy.fromJson);
  }

  Future<Legacy> get(String id) async {
    final res = await guardApi(() => _dio.get<Json>('$_base/$id'));
    return Legacy.fromJson(res.data!);
  }

  Future<Legacy> create(String name) async {
    final res = await guardApi(
      () => _dio.post<Json>(_base, data: {'name': name}),
    );
    return Legacy.fromJson(res.data!);
  }

  Future<Legacy> rename(String id, String name) async {
    final res = await guardApi(
      () => _dio.put<Json>('$_base/$id', data: {'name': name}),
    );
    return Legacy.fromJson(res.data!);
  }

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<Json>('$_base/$id'));

  // There is no endpoint to edit an account; change it by delete + add.
  Future<Account> addAccount(String legacyId, Account account) async {
    final res = await guardApi(
      () => _dio.post<Json>('$_base/$legacyId/account', data: account.toJson()),
    );
    return Account.fromJson(res.data!);
  }

  Future<void> removeAccount(String legacyId, String accountId) =>
      guardApi(() => _dio.delete<Json>('$_base/$legacyId/account/$accountId'));
}
