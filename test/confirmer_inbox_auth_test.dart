import 'package:diealog_app/data/providers.dart';
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
}
