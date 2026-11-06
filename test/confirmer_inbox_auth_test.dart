import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/core/storage/confirmer_session_store.dart';
import 'package:diealog_app/data/models/confirmer_access.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:diealog_app/features/auth/auth_controller.dart';
import 'package:diealog_app/features/transition/confirmer_cases_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedOutAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.signedOut;
}

class _SignedInAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.signedIn;
}

void main() {
  test(
    'received invitations do not call the owner API while signed out',
    () async {
      var requested = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requested = true;
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_SignedOutAuthController.new),
          transitionRepositoryProvider.overrideWithValue(
            TransitionRepository(dio),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        dio.close();
      });

      final owners = await container.read(designatingUsersProvider.future);
      expect(owners, isEmpty);
      expect(requested, isFalse);
    },
  );

  test('refreshing the inbox keeps a valid confirmer token', () async {
    var accessClaims = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/confirmers/access')) {
              accessClaims++;
              handler.resolve(
                Response<List<dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const [],
                ),
              );
              return;
            }
            handler.resolve(
              Response<List<dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const [],
              ),
            );
          },
        ),
      );
    final store = InMemoryConfirmerSessionStore();
    await store.upsert(
      ConfirmerSession(
        confirmerId: 'confirmer-1',
        ownerUserId: 'owner-1',
        name: '내 이름',
        authToken: 'still-valid',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedInAuthController.new),
        confirmerSessionStoreProvider.overrideWithValue(store),
        transitionRepositoryProvider.overrideWithValue(
          TransitionRepository(dio),
        ),
        confirmerRepositoryProvider.overrideWithValue(ConfirmerRepository(dio)),
      ],
    );
    addTearDown(() {
      container.dispose();
      dio.close();
    });

    expect(
      (await container.read(confirmerInboxProvider.future)).single.error,
      isNull,
    );
    container.invalidate(confirmerInboxProvider);
    expect(
      (await container.read(confirmerInboxProvider.future)).single.error,
      isNull,
    );
    expect(accessClaims, 0);
  });
}
