import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/json.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  static const _base = '/profile/protected';

  final Dio _dio;

  Future<Profile> fetch() async {
    final res = await guardApi(() => _dio.get<Json>(_base));
    return Profile.fromJson(res.data!);
  }

  Future<UserConfig> updateConfig(UserConfig config) async {
    final res = await guardApi(
      () => _dio.put<Json>('$_base/config', data: config.toJson()),
    );
    return UserConfig.fromJson(res.data!);
  }

  /// `PUT /profile/protected/image`, multipart field `profile_image`.
  Future<Profile> updateImage(String filePath) async {
    final form = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(filePath),
    });
    final res = await guardApi(
      () => _dio.put<Json>('$_base/image', data: form),
    );
    return Profile.fromJson(res.data!);
  }
}
