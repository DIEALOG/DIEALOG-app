import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/auth_interceptor.dart';
import '../core/storage/local_prefs.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/confirmer_session_store.dart';
import '../features/auth/auth_controller.dart';
import 'mock/mock_api_interceptor.dart';
import 'mock/mock_backend.dart';
import 'repositories/auth_repository.dart';
import 'repositories/confirmer_repository.dart';
import 'repositories/last_word_repository.dart';
import 'repositories/legacy_repository.dart';
import 'repositories/mock/afterlife_repository.dart';
import 'repositories/mock/settings_repository.dart';
import 'repositories/mock/verification_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/stakeholder_repository.dart';
import 'repositories/transition_repository.dart';
import 'repositories/stakeholder_task_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final confirmerSessionStoreProvider = Provider<ConfirmerSessionStore>(
  (ref) => SecureConfirmerSessionStore(),
);

final localSettingsStoreProvider = Provider<LocalSettingsStore>(
  (ref) => SecureLocalSettingsStore(),
);

/// One fake backend for the whole app, so writes are visible on every screen.
final mockBackendProvider = Provider<MockBackend>(
  (ref) => MockBackend.seeded(),
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
  if (Env.useMockApi) {
    final backend = ref.watch(mockBackendProvider);
    dio.interceptors.add(MockApiInterceptor(backend: backend));
    refreshDio.interceptors.add(MockApiInterceptor(backend: backend));
  }
  ref.onDispose(() {
    dio.close();
    refreshDio.close();
  });
  return dio;
});

final authRepositoryProvider = Provider(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
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

final transitionRepositoryProvider = Provider(
  (ref) => TransitionRepository(ref.watch(dioProvider)),
);

final stakeholderTaskRepositoryProvider = Provider(
  (ref) => StakeholderTaskRepository(ref.watch(dioProvider)),
);

final confirmerRepositoryProvider = Provider(
  (ref) => ConfirmerRepository(ref.watch(dioProvider)),
);

final lastWordRepositoryProvider = Provider(
  (ref) => LastWordRepository(ref.watch(dioProvider)),
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
  (ref) => MockAfterlifeRepository(seeded: Env.useMockApi),
);
