import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

enum AuthStatus { unknown, signedIn, signedOut }

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    Future.microtask(_restore);
    return AuthStatus.unknown;
  }

  Future<void> _restore() async {
    final hasSession = await ref.read(authRepositoryProvider).hasSession();
    if (!ref.mounted) return;
    state = hasSession ? AuthStatus.signedIn : AuthStatus.signedOut;
  }

  /// Throws `ApiException` on failure.
  Future<void> login({required String email, required String password}) async {
    await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    if (ref.mounted) state = AuthStatus.signedIn;
  }

  /// Throws `ApiException` on failure.
  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    await ref.read(authRepositoryProvider).signup(
          name: name,
          email: email,
          password: password,
          phoneNumber: phoneNumber,
        );
    if (ref.mounted) state = AuthStatus.signedIn;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (ref.mounted) state = AuthStatus.signedOut;
  }

  /// Called by the network layer when the refresh token is rejected.
  void sessionExpired() => state = AuthStatus.signedOut;
}
