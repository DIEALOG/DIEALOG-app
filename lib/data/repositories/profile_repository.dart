import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/json.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<Profile> fetch() async {
    final res = await guardApi(() => _dio.get<Json>('/profile/protected'));
    return Profile.fromJson(res.data!);
  }

  Future<void> updateTestament(String testament) => guardApi(
        () => _dio.put<Json>(
          '/profile/protected/testament',
          data: {'testament': testament},
        ),
      );
}
