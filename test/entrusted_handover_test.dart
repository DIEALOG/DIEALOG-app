import 'package:diealog_app/core/storage/confirmer_session_store.dart';
import 'package:diealog_app/data/models/account_handling_task.dart';
import 'package:diealog_app/data/models/confirmer_access.dart';
import 'package:diealog_app/data/models/designating_user.dart';
import 'package:diealog_app/data/models/last_word.dart';
import 'package:diealog_app/data/models/transition_case.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/data/repositories/entrusted_repository.dart';
import 'package:diealog_app/data/repositories/last_word_repository.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a session remembers case ids across refreshes', () async {
    final store = InMemoryConfirmerSessionStore();
    final base = ConfirmerSession(
      confirmerId: 'c1',
      ownerUserId: 'owner-1',
      name: '강태호',
      authToken: 'token-1',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    await store.upsert(base.withCaseIds(['case-a']));
    // Re-linking issues a new token but must not forget the case already seen,
    // because a confirmed case drops out of /transition/confirmer/cases.
    final relinked = ConfirmerSession(
      confirmerId: 'c1',
      ownerUserId: 'owner-1',
      name: '강태호',
      authToken: 'token-2',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    final previous = (await store.read()).single;
    await store.upsert(relinked.withCaseIds(previous.knownCaseIds));

    final saved = (await store.read()).single;
    expect(saved.authToken, 'token-2');
    expect(saved.knownCaseIds, ['case-a']);
    expect(ConfirmerSession.fromJson(saved.toJson()).knownCaseIds, [
      'case-a',
    ], reason: 'case ids have to survive a round trip through storage');
  });

  test('case ids merge without duplicates and drop blanks', () {
    final session = ConfirmerSession(
      confirmerId: 'c1',
      ownerUserId: 'owner-1',
      name: '강태호',
      authToken: 't',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      knownCaseIds: const ['case-a'],
    );
    final merged = session.withCaseIds(['case-a', '', 'case-b']);
    expect(merged.knownCaseIds, ['case-a', 'case-b']);
  });

  test('a task reports which assignee row belongs to this login', () {
    final task = AccountHandlingTask.fromJson(<String, dynamic>{
      'id': 'task-1',
      'transition_case_id': 'case-a',
      'account_id': 'account-1',
      'status': 'in_progress',
      'action_snapshot': 'backup-and-delete',
      'action_message_snapshot': '사진만 백업해 줘',
      'request_count': 1,
      'completed_at': null,
      'assignees': [
        {
          'id': 'a1',
          'name': '강태호',
          'status': 'pending',
          'stakeholder_id': 's1',
        },
        {
          'id': 'a2',
          'name': '한수아',
          'status': 'confirmed',
          'stakeholder_id': 's2',
        },
      ],
      'events': [
        {'event_type': 'task_created', 'created_at': '2026-11-03T10:00:00Z'},
        {'event_type': 'request_issued', 'created_at': '2026-11-03T11:00:00Z'},
      ],
    });

    expect(task.status, AccountHandlingStatus.inProgress);
    expect(task.action.label, '백업 후 삭제');
    expect(task.canRequest, isTrue);
    expect(task.assignees, hasLength(2));
    expect(task.assigneeFor({'s1'})?.name, '강태호');
    expect(task.assigneeFor({'s2'})?.status, AssigneeStatus.confirmed);
    expect(task.assigneeFor({'other'}), isNull);
    expect(task.events.first.label, '처리 작업이 만들어졌어요');
  });

  test(
    'a received letter stays hidden until the transition is confirmed',
    () async {
      final sessions = InMemoryConfirmerSessionStore();
      await sessions.upsert(
        ConfirmerSession(
          confirmerId: 'confirmer-1',
          ownerUserId: 'owner-1',
          name: '받는 사람',
          authToken: 'confirmer-token',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          knownCaseIds: const ['case-1'],
        ),
      );
      final confirmer = _FakeConfirmerRepository();
      final letters = _FakeLastWordRepository();
      final repository = EntrustedRepository(
        transitions: _FakeTransitionRepository(),
        confirmers: confirmer,
        lastWords: letters,
        sessions: sessions,
      );

      final waiting = (await repository.listOwners()).single;
      expect(waiting.letters, isEmpty);
      expect(letters.readCount, 0);

      confirmer.status = TransitionCaseStatus.confirmed;
      final opened = (await repository.listOwners()).single;
      expect(opened.letters.single.title, '남긴 말');
      expect(letters.readCount, 1);
    },
  );
}

class _FakeTransitionRepository extends TransitionRepository {
  _FakeTransitionRepository() : super(Dio());

  @override
  Future<List<ConfirmerAccess>> claimAccess() async => [];

  @override
  Future<List<DesignatingUser>> listDesignatingUsers() async => [
    const DesignatingUser(id: 'owner-1', name: '보내는 사람'),
  ];

  @override
  Future<List<AccountHandlingTask>> listTasks(String caseId) async => [];
}

class _FakeConfirmerRepository extends ConfirmerRepository {
  _FakeConfirmerRepository() : super(Dio());

  TransitionCaseStatus status = TransitionCaseStatus.waitingPeriod;

  @override
  Future<List<TransitionCase>> listCases(String authToken) async => [];

  @override
  Future<TransitionCase> getCase(String authToken, String id) async =>
      TransitionCase(
        id: id,
        userId: 'owner-1',
        status: status,
        minimumConfirmers: 2,
        waitingPeriodDays: 7,
        requestedAt: DateTime.utc(2026, 11, 1),
      );
}

class _FakeLastWordRepository extends LastWordRepository {
  _FakeLastWordRepository() : super(Dio());

  int readCount = 0;

  @override
  Future<List<LastWord>> listAddressedToMe(String ownerId) async {
    readCount++;
    return [const LastWord(title: '남긴 말', message: '고마워')];
  }
}
