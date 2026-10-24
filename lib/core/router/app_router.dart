import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
}

final routerProvider = Provider<GoRouter>((ref) {
  final status = ValueNotifier(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => status.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: status,
    redirect: (context, state) {
      final location = state.matchedLocation;
      return switch (status.value) {
        AuthStatus.unknown => location == Routes.splash ? null : Routes.splash,
        AuthStatus.signedOut =>
          location == Routes.login ? null : Routes.login,
        AuthStatus.signedIn =>
          location == Routes.splash || location == Routes.login
              ? Routes.home
              : null,
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    status.dispose();
  });
  return router;
});
