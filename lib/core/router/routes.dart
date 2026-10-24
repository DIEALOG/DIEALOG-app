abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signupName = '/signup/name';
  static const signupEmail = '/signup/email';
  static const signupPassword = '/signup/password';
  static const signupPhone = '/signup/phone';
  static const signupOtp = '/signup/otp';
  static const signupTerms = '/signup/terms';
  static const signupComplete = '/signup/complete';
  static const home = '/home';
}

abstract final class AuthPaths {
  static bool isPublic(String location) =>
      location == Routes.welcome ||
      location == Routes.login ||
      (location.startsWith('/signup') && location != Routes.signupComplete);
}
