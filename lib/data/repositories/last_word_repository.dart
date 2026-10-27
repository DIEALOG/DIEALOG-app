import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/json.dart';
import '../models/last_word.dart';

class LastWordRepository {
  LastWordRepository(this._dio);

  static const _base = '/last-word/protected';

  final Dio _dio;

  Future<List<LastWord>> list() async {
    final res = await guardApi(() => _dio.get<List<dynamic>>(_base));
    return parseList(res.data, LastWord.fromJson);
  }

  Future<LastWord> get(String id) async {
    final res = await guardApi(() => _dio.get<Json>('$_base/$id'));
    return LastWord.fromJson(res.data!);
  }

  Future<LastWord> create(LastWord lastWord) async {
    final res = await guardApi(
      () => _dio.post<Json>(_base, data: lastWord.toJson()),
    );
    return LastWord.fromJson(res.data!);
  }

  Future<LastWord> update(String id, LastWord lastWord) async {
    final res = await guardApi(
      () => _dio.put<Json>('$_base/$id', data: lastWord.toJson()),
    );
    return LastWord.fromJson(res.data!);
  }

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<Json>('$_base/$id'));
}
