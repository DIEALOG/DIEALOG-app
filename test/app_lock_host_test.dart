import 'package:diealog_app/core/lock/app_lock_host.dart';
import 'package:diealog_app/core/lock/biometric_auth.dart';
import 'package:diealog_app/core/storage/local_prefs.dart';
import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedInAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.signedIn;
}

class _BiometricPrompt extends BiometricAuth {
  int calls = 0;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return true;
  }
}

void main() {
  testWidgets('a locked app prompts on its own', (tester) async {
    final store = InMemoryLocalSettingsStore();
    await store.write(const LocalSettings(lockByFaceId: true));
    final prompt = _BiometricPrompt();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_SignedInAuthController.new),
          localSettingsStoreProvider.overrideWithValue(store),
          biometricAuthProvider.overrideWithValue(prompt),
        ],
        child: const MaterialApp(home: AppLockHost(child: SizedBox.shrink())),
      ),
    );
    await tester.pumpAndSettle();

    expect(prompt.calls, 1);
    expect(find.text('앱이 잠겨 있어요'), findsNothing);
  });
}
