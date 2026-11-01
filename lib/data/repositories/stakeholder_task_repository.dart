import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_interceptor.dart';
import '../models/account_handling_task.dart';
import '../models/json.dart';

class StakeholderTaskRepository {
  const StakeholderTaskRepository(this._dio);
  final Dio _dio;

  Future<AccountHandlingTask> submitResult(
    String token, {
    required bool success,
    String? message,
  }) async {
    final response = await guardApi(
      () => _dio.post<Json>(
        '/transition/stakeholder-tasks/result',
        data: compact({'token': token, 'success': success, 'message': message}),
        options: Options(extra: {AuthInterceptor.skipAuth: true}),
      ),
    );
    return AccountHandlingTask.fromJson(response.data!);
  }
}
