import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/features/legacy/legacy_providers.dart';
import 'package:diealog_app/features/legacy/register/register_steps.dart';
import 'package:diealog_app/features/legacy/widgets/account_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const group = StakeholderGroup(
    id: 'family',
    name: '가족',
    stakeholderIds: ['a', 'b'],
  );
  const overview = DataOverview(
    legacies: [],
    groups: {'family': group},
    people: {
      'a': Stakeholder(id: 'a', name: '첫 사람'),
      'b': Stakeholder(id: 'b', name: '둘째 사람'),
    },
  );

  testWidgets('registration preview counts group IDs without embedded people', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataOverviewProvider.overrideWith((ref) async => overview)],
        child: const MaterialApp(
          home: Scaffold(
            body: ConfirmStep(
              account: Account(name: '계정'),
              serviceLabel: '카카오톡',
              people: {},
              groups: {'family'},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2명'), findsOneWidget);
    expect(find.text('첫 사람'), findsOneWidget);
    expect(find.text('둘째 사람'), findsOneWidget);
  });

  testWidgets('account detail resolves group members from overview', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataOverviewProvider.overrideWith((ref) async => overview)],
        child: const MaterialApp(
          home: Scaffold(
            body: AccountAudienceSection(
              account: Account(name: '계정', stakeholderGroupIds: ['family']),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2명'), findsOneWidget);
    expect(find.text('첫 사람, 둘째 사람'), findsOneWidget);
  });
}
