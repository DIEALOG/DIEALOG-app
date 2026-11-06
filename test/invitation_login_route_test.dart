import 'package:diealog_app/core/router/app_router.dart';
import 'package:diealog_app/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MutableAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.signedOut;

  void signIn() => state = AuthStatus.signedIn;
}

class _RestoringAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.unknown;

  void signOut() => state = AuthStatus.signedOut;

  void signIn() => state = AuthStatus.signedIn;
}

void main() {
  testWidgets('an invitation link waits for login and keeps its code', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_MutableAuthController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/invitation?token=invite-123');
    await tester.pumpAndSettle();
    expect(find.text('로그인'), findsWidgets);
    expect(find.text('확인자 초대'), findsNothing);

    (container.read(authControllerProvider.notifier) as _MutableAuthController)
        .signIn();
    await tester.pumpAndSettle();
    expect(find.text('확인자 초대'), findsOneWidget);
    final codeField = tester.widget<TextField>(find.byType(TextField));
    expect(codeField.controller?.text, 'invite-123');
  });

  testWidgets('a cold-start invitation survives auth restoration', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_RestoringAuthController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/invitation?token=cold-start-code');
    await tester.pumpAndSettle();
    (container.read(
      authControllerProvider.notifier,
    ) as _RestoringAuthController).signOut();
    await tester.pumpAndSettle();
    expect(find.text('로그인'), findsWidgets);

    (container.read(
      authControllerProvider.notifier,
    ) as _RestoringAuthController).signIn();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'cold-start-code',
    );
  });
}
