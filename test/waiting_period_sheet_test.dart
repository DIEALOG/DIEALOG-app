import 'package:diealog_app/data/models/transition_policy.dart';
import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:diealog_app/features/settings/policy_sheets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PolicyRepository extends TransitionRepository {
  _PolicyRepository() : super(Dio());

  int? savedDays;

  @override
  Future<TransitionPolicy> updatePolicy({
    int? aliveCheckIntervalDays,
    int? minimumConfirmers,
    int? waitingPeriodDays,
  }) async {
    savedDays = waitingPeriodDays;
    return TransitionPolicy(waitingPeriodDays: waitingPeriodDays ?? 7);
  }
}

void main() {
  testWidgets('the waiting-period sheet saves a custom zero-day value', (
    tester,
  ) async {
    final repo = _PolicyRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [transitionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTransitionCriteriaSheet(
                  context,
                  const TransitionPolicy(),
                ),
                child: const Text('기준 열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('기준 열기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(repo.savedDays, 0);
    expect(find.text('대기 기간(일)'), findsNothing);
  });
}
