import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/auth_interceptor.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/auth_controller.dart';
import 'repositories/auth_repository.dart';
import 'repositories/legacy_repository.dart';
import 'repositories/mock/afterlife_repository.dart';
import 'repositories/mock/settings_repository.dart';
import 'repositories/mock/verification_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/stakeholder_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
  );
  final dio = Dio(options);
  final refreshDio = Dio(options);
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      refreshDio: refreshDio,
      storage: ref.watch(tokenStorageProvider),
      onSessionExpired: () =>
          ref.read(authControllerProvider.notifier).sessionExpired(),
    ),
  );
  ref.onDispose(() {
    dio.close();
    refreshDio.close();
  });
  return dio;
});

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

final legacyRepositoryProvider = Provider(
  (ref) => LegacyRepository(ref.watch(dioProvider)),
);

final stakeholderRepositoryProvider = Provider(
  (ref) => StakeholderRepository(ref.watch(dioProvider)),
);

// Backed by mocks until the backend exposes these features. Swap the
// implementation here; callers only see the interface.

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => MockVerificationRepository(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => MockSettingsRepository(),
);

final afterlifeRepositoryProvider = Provider<AfterlifeRepository>(
  (ref) => MockAfterlifeRepository(),
);
