import 'package:diealog_app/core/storage/confirmer_session_store.dart';
import 'package:diealog_app/data/models/confirmer_access.dart';
import 'package:diealog_app/data/models/transition_case.dart';
import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/features/transition/confirmer_cases_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaseRepository extends ConfirmerRepository {
  _CaseRepository() : super(Dio());

  static final caseItem = TransitionCase(
    id: 'case-1',
    userId: 'owner-1',
    status: TransitionCaseStatus.pendingConfirmation,
    minimumConfirmers: 2,
    waitingPeriodDays: 7,
    requestedAt: DateTime.utc(2026, 11, 5),
  );

  @override
  Future<TransitionCase> getCase(String authToken, String id) async => caseItem;

  @override
  Future<List<TransitionConfirmation>> listConfirmations(
    String authToken,
    String caseId,
  ) async => [
    const TransitionConfirmation(
      confirmerId: 'confirmer-1',
      decision: TransitionDecision.disagree,
    ),
  ];
}

void main() {
  testWidgets('the owner and my saved response are visible on revisit', (
    tester,
  ) async {
    final store = InMemoryConfirmerSessionStore();
    final session = ConfirmerSession(
      confirmerId: 'confirmer-1',
      ownerUserId: 'owner-1',
      name: '내 이름',
      authToken: 'confirmer-token',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
    await store.upsert(session);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          confirmerSessionStoreProvider.overrideWithValue(store),
          confirmerRepositoryProvider.overrideWithValue(_CaseRepository()),
        ],
        child: MaterialApp(
          home: ConfirmerCaseDetailScreen(
            session: session,
            caseId: 'case-1',
            ownerName: '서연',
            initialCase: _CaseRepository.caseItem,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('서연님의 사후 전환'), findsOneWidget);
    expect(find.text('내 응답: 사실이 아니에요'), findsOneWidget);
    final negative = tester.getRect(find.byType(OutlinedButton));
    final positive = tester.getRect(find.byType(FilledButton));
    expect(negative.width, positive.width);
    expect(negative.height, 48);
    expect(positive.height, 48);
  });
}
