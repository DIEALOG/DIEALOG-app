import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/data/repositories/legacy_repository.dart';
import 'package:diealog_app/features/legacy/account_edit_screen.dart';
import 'package:diealog_app/features/legacy/legacy_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _account = Account(
  id: 'account-1',
  legacyId: 'legacy-1',
  name: '사진 보관함',
  type: AccountType(service: AccountService.kakaoTalk),
  action: AccountAction(kind: AccountActionKind.delete),
  accountId: 'me@example.com',
  accountPassword: 'secret',
  dataLocation: '클라우드',
);

const _key = (legacyId: 'legacy-1', accountId: 'account-1');

class _FakeLegacyRepository extends LegacyRepository {
  _FakeLegacyRepository() : super(Dio());

  final removed = <String>[];
  Account? updated;

  @override
  Future<void> removeAccount(String legacyId, String accountId) async =>
      removed.add('$legacyId/$accountId');

  @override
  Future<Account> updateAccount(String legacyId, Account account) async {
    updated = account;
    return account;
  }
}

/// Catches what the editor pops, which only arrives after the screen closes.
class _Popped {
  AccountEdited? result;
}

Future<_Popped> _open(
  WidgetTester tester,
  _FakeLegacyRepository repository,
) async {
  final popped = _Popped();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  popped.result = await context.push<AccountEdited>('/edit'),
              child: const Text('열기'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const AccountEditScreen(
              legacyId: 'legacy-1',
              accountId: 'account-1',
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        legacyRepositoryProvider.overrideWithValue(repository),
        accountProvider(_key).overrideWith((ref) async => _account),
        dataOverviewProvider.overrideWith(
          (ref) async =>
              const DataOverview(legacies: [], groups: {}, people: {}),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  testWidgets('the edit screen loads the account into editable fields', (
    tester,
  ) async {
    await _open(tester, _FakeLegacyRepository());

    // The basics used to be read-only text; they have to arrive as values the
    // user can change.
    expect(find.widgetWithText(TextField, '사진 보관함'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'me@example.com'), findsOneWidget);
    expect(find.widgetWithText(TextField, '클라우드'), findsOneWidget);
    expect(find.text('카카오톡'), findsOneWidget);
    // A stored password is never poured back into the form.
    expect(find.widgetWithText(TextField, 'secret'), findsNothing);
    expect(find.text('비워 두면 저장된 비밀번호를 그대로 둬요.'), findsOneWidget);
  });

  testWidgets('deleting asks first, then closes with a delete result', (
    tester,
  ) async {
    final repository = _FakeLegacyRepository();
    final popped = await _open(tester, repository);

    // Reachable from the header, not buried under the whole form.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('이 계정을 삭제할까요?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    expect(repository.removed, isEmpty, reason: 'cancel must not delete');

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(repository.removed, ['legacy-1/account-1']);
    expect(find.text('열기'), findsOneWidget, reason: 'the editor should close');
    expect(popped.result?.deleted, isTrue);
  });

  testWidgets('a rename resends the password so it is not stranded', (
    tester,
  ) async {
    final repository = _FakeLegacyRepository();
    await _open(tester, repository);

    await tester.enterText(
      find.widgetWithText(TextField, '사진 보관함'),
      '가족 사진',
    );
    await tester.tap(find.text('변경 사항 저장'));
    await tester.pumpAndSettle();

    expect(repository.updated?.name, '가족 사진');
    expect(
      repository.updated?.accountPassword,
      'secret',
      reason: 'the server files the password under the account name',
    );
  });

  testWidgets('an unchanged name sends no password at all', (tester) async {
    final repository = _FakeLegacyRepository();
    await _open(tester, repository);

    await tester.enterText(
      find.widgetWithText(TextField, 'me@example.com'),
      'new@example.com',
    );
    await tester.tap(find.text('변경 사항 저장'));
    await tester.pumpAndSettle();

    expect(repository.updated?.accountId, 'new@example.com');
    expect(
      repository.updated?.accountPassword,
      isNull,
      reason: 'omitting it leaves the stored credential untouched',
    );
  });
}
