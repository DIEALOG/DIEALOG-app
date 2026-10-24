import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup/signup_complete_screen.dart';
import '../../features/auth/signup/signup_email_screen.dart';
import '../../features/auth/signup/signup_name_screen.dart';
import '../../features/auth/signup/signup_otp_screen.dart';
import '../../features/auth/signup/signup_password_screen.dart';
import '../../features/auth/signup/signup_phone_screen.dart';
import '../../features/auth/signup/signup_terms_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import 'routes.dart';

export 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final status = ValueNotifier(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => status.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: status,
    redirect: (context, state) {
      final location = state.matchedLocation;
      return switch (status.value) {
        AuthStatus.unknown =>
          location == Routes.splash ? null : Routes.splash,
        AuthStatus.signedOut =>
          AuthPaths.isPublic(location) ? null : Routes.welcome,
        AuthStatus.signedIn => location.startsWith('/signup')
            ? null
            : (location == Routes.splash || AuthPaths.isPublic(location)
                ? Routes.home
                : null),
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signupName,
        builder: (context, state) => const SignupNameScreen(),
      ),
      GoRoute(
        path: Routes.signupEmail,
        builder: (context, state) => const SignupEmailScreen(),
      ),
      GoRoute(
        path: Routes.signupPassword,
        builder: (context, state) => const SignupPasswordScreen(),
      ),
      GoRoute(
        path: Routes.signupPhone,
        builder: (context, state) => const SignupPhoneScreen(),
      ),
      GoRoute(
        path: Routes.signupOtp,
        builder: (context, state) => const SignupOtpScreen(),
      ),
      GoRoute(
        path: Routes.signupTerms,
        builder: (context, state) => const SignupTermsScreen(),
      ),
      GoRoute(
        path: Routes.signupComplete,
        builder: (context, state) => const SignupCompleteScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    status.dispose();
  });
  return router;
});
