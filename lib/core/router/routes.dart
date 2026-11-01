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
  static const invitation = '/invitation';
  static const notifications = '/notifications';
  static const taskResult = '/task-result';

  static const accountNew = '/account/new';
  static const accountDetail = '/account/:legacyId/:accountId';
  static const accountEdit = 'edit';

  static String accountDetailOf(String legacyId, String accountId) =>
      '/account/$legacyId/$accountId';

  static String accountEditOf(String legacyId, String accountId) =>
      '${accountDetailOf(legacyId, accountId)}/$accountEdit';
}

abstract final class AuthPaths {
  static bool isPublic(String location) =>
      location == Routes.welcome ||
      location == Routes.login ||
      location == Routes.invitation ||
      location == Routes.taskResult ||
      (location.startsWith('/signup') && location != Routes.signupComplete);
}
