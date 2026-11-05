import 'package:diealog_app/core/storage/local_prefs.dart';
import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/last_word.dart';
import 'package:diealog_app/data/models/legacy.dart';
import 'package:diealog_app/data/models/profile.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_confirmer.dart';
import 'package:diealog_app/data/models/transition_policy.dart';
import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/features/home/home_guide.dart';
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
              policy: TransitionPolicy(),
            ),
          ),
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
          localSettingsStoreProvider.overrideWithValue(
            InMemoryLocalSettingsStore(),
          ),
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
    // One continuous bar per card, filled by ratio: 1 of 2 accounts assigned,
    // and 2 of the 4 guide steps done.
    final bars = tester
        .widgetList<ProgressBar>(find.byType(ProgressBar))
        .toList();
    expect(bars, hasLength(2));
    expect(bars.first.value, 0.5);
    expect(find.text('시작 안내'), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.textContaining('공개 대상 1개를 더 지정해 주세요'));
    expect(selectedTab, 1);
  });

  testWidgets('the guide retires once every step is done', (tester) async {
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
                  ],
                ),
              ],
              stakeholders: [Stakeholder(id: 'person', name: '친구')],
              groups: [],
              lastWords: [LastWord(title: '안녕', message: '고마워')],
              entrusted: [],
              confirmers: [
                TransitionConfirmer(
                  id: 'accepted',
                  name: '친구',
                  status: ConfirmerStatus.accepted,
                ),
              ],
              policy: TransitionPolicy(),
            ),
          ),
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
          localSettingsStoreProvider.overrideWithValue(
            InMemoryLocalSettingsStore(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: HomeScreen(onSelectTab: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('시작 안내'), findsNothing);
  });
}
