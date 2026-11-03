import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/legacy.dart';
import 'package:diealog_app/data/models/profile.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_confirmer.dart';
import 'package:diealog_app/features/home/home_screen.dart';
import 'package:diealog_app/features/notifications/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home CTA opens data and counts only accepted confirmers', (
    tester,
  ) async {
    int? selectedTab;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeSnapshotProvider.overrideWith(
            (ref) async => const HomeSnapshot(
              profile: Profile(name: '테스트', email: 'test@example.com'),
              legacies: [
                Legacy(
                  id: 'legacy',
                  name: '내 데이터',
                  accounts: [
                    Account(name: '지정됨', stakeholderIds: ['person']),
                    Account(name: '빈 그룹', stakeholderGroupIds: ['empty']),
                  ],
                ),
              ],
              stakeholders: [Stakeholder(id: 'person', name: '친구')],
              groups: [StakeholderGroup(id: 'empty', name: '빈 그룹')],
              lastWords: [],
              entrusted: [],
              confirmers: [
                TransitionConfirmer(
                  id: 'pending',
                  name: '친구',
                  status: ConfirmerStatus.pending,
                ),
              ],
            ),
          ),
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(onSelectTab: (index) => selectedTab = index),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.textContaining('수락한 확인자 0'), findsOneWidget);
    await tester.tap(find.textContaining('공개 대상 1개를 더 지정해 주세요'));
    expect(selectedTab, 1);
  });
}
