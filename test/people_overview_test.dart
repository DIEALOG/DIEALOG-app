import 'package:diealog_app/data/models/account.dart';
import 'package:diealog_app/data/models/legacy.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_confirmer.dart';
import 'package:diealog_app/data/repositories/mock/afterlife_repository.dart';
import 'package:diealog_app/features/legacy/legacy_providers.dart';
import 'package:diealog_app/features/stakeholder/people_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts direct and group access without counting one account twice', () {
    const group = StakeholderGroup(
      id: 'g1',
      name: '가족',
      stakeholderIds: ['s1', 's2'],
    );
    final overview = PeopleOverview(
      data: const DataOverview(
        legacies: [
          Legacy(
            id: 'l1',
            name: '내 데이터',
            accounts: [
              Account(
                name: '첫 데이터',
                stakeholderIds: ['s1'],
                stakeholderGroupIds: ['g1'],
              ),
              Account(name: '두 번째 데이터', stakeholderGroupIds: ['g1']),
            ],
          ),
        ],
        groups: {'g1': group},
        people: {
          's1': Stakeholder(id: 's1', name: '이도윤'),
          's2': Stakeholder(id: 's2', name: '김정희'),
        },
      ),
      confirmers: const [
        TransitionConfirmer(
          id: 'c1',
          name: '이도윤',
          stakeholderId: 's1',
          status: ConfirmerStatus.accepted,
        ),
        TransitionConfirmer(
          id: 'c2',
          name: '김정희',
          stakeholderId: 's2',
          status: ConfirmerStatus.revoked,
        ),
      ],
    );

    expect(overview.accountCountFor('s1'), 2);
    expect(overview.accountCountFor('s2'), 2);
    expect(overview.accountCountForGroup('g1'), 2);
    expect(overview.activeConfirmers.length, 1);
    expect(overview.confirmerFor('s2'), isNull);
  });

  test('real-server mode has no fabricated entrusted records', () async {
    final repo = MockAfterlifeRepository();
    expect(await repo.listEntrusted(), isEmpty);
    expect(await repo.listReceivedMessages(), isEmpty);
  });
}
