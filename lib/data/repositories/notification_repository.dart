import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/app_notification.dart';
import '../models/json.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  static const _base = '/notification/protected';
  final Dio _dio;

  Future<List<AppNotification>> list() async {
    final response = await guardApi(() => _dio.get<List<dynamic>>(_base));
    return parseList(response.data, AppNotification.fromJson);
  }

  Future<int> unreadCount() async {
    final response = await guardApi(
      () => _dio.get<Json>('$_base/unread-count'),
    );
    return response.data?['count'] as int? ?? 0;
  }

  Future<void> markRead(String id) =>
      guardApi(() => _dio.patch<Json>('$_base/$id'));

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<Json>('$_base/$id'));
}
