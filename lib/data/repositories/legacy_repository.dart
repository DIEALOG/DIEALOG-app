import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/account.dart';
import '../models/json.dart';
import '../models/legacy.dart';

class LegacyRepository {
  LegacyRepository(this._dio);

  static const _base = '/legacy/protected';

  final Dio _dio;

  /// `GET /legacy/protected` returns a bare array of legacies, each with its
  /// accounts in list shape (ids only, no credentials).
  Future<List<Legacy>> list() async {
    final res = await guardApi(() => _dio.get<List<dynamic>>(_base));
    return parseList(res.data, Legacy.fromJson);
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

  /// Detail shape: stakeholders, groups and the decrypted password.
  Future<Account> getAccount(String legacyId, String accountId) async {
    final res = await guardApi(
      () => _dio.get<Json>('$_base/$legacyId/account/$accountId'),
    );
    return Account.fromJson(res.data!);
  }

  Future<Account> addAccount(String legacyId, Account account) async {
    final res = await guardApi(
      () => _dio.post<Json>('$_base/$legacyId/account', data: account.toJson()),
    );
    return Account.fromJson(res.data!);
  }

  Future<void> removeAccount(String legacyId, String accountId) =>
      guardApi(() => _dio.delete<Json>('$_base/$legacyId/account/$accountId'));

  /// The API has no account update endpoint, so an edit is a delete followed
  /// by a create. [account] must carry every field the new one should keep,
  /// including the password.
  Future<Account> replaceAccount(String legacyId, Account account) async {
    final created = await addAccount(legacyId, account);
    if (account.id.isNotEmpty) {
      await removeAccount(legacyId, account.id);
    }
    return created;
  }
}
