import 'package:diealog_app/core/storage/confirmer_session_store.dart';
import 'package:diealog_app/core/storage/entrusted_case_store.dart';
import 'package:diealog_app/data/models/account_handling_task.dart';
import 'package:diealog_app/data/models/app_notification.dart';
import 'package:diealog_app/data/models/confirmer_access.dart';
import 'package:diealog_app/data/models/designating_user.dart';
import 'package:diealog_app/data/models/last_word.dart';
import 'package:diealog_app/data/models/profile.dart';
import 'package:diealog_app/data/models/transition_case.dart';
import 'package:diealog_app/data/repositories/confirmer_repository.dart';
import 'package:diealog_app/data/repositories/entrusted_repository.dart';
import 'package:diealog_app/data/repositories/last_word_repository.dart';
import 'package:diealog_app/data/repositories/notification_repository.dart';
import 'package:diealog_app/data/repositories/profile_repository.dart';
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
      'legacy_id': 'legacy-1',
      'type': 'KakaoTalk',
      'name': '카카오톡',
      'account_identifier': 'seoyeon@example.com',
      'account_password': 'private-password',
      'data_location': '클라우드',
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
    expect(task.name, '카카오톡');
    expect(task.accountIdentifier, 'seoyeon@example.com');
    expect(task.accountPassword, 'private-password');
    expect(task.dataLocation, '클라우드');
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
        notifications: _FakeNotificationRepository(),
        profiles: _FakeProfileRepository(),
        caseStore: InMemoryEntrustedCaseStore(),
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

  test('a non-confirmer keeps confirmed owner IDs after the notification is deleted', () async {
    final notifications = _FakeNotificationRepository()
      ..items = [
        AppNotification.fromJson({
          'id': 'notice-1',
          'receiver_id': 'user-1',
          'message': '전환 확정',
          'is_read': false,
          'type': 'transition',
          'metadata': {
            'type': 'transition_confirmed',
            'target_user_id': 'owner-1',
            'target_user_name': '보내는 사람',
            'case_id': 'case-1',
          },
        }),
      ];
    final links = InMemoryEntrustedCaseStore();
    final transitions = _FakeTransitionRepository()
      ..owners = []
      ..tasks = [
        AccountHandlingTask.fromJson({
          'id': 'task-1',
          'transition_case_id': 'case-1',
          'account_id': 'account-1',
          'status': 'pending',
          'action_snapshot': 'delete',
          'request_count': 0,
        }),
      ];
    final repository = EntrustedRepository(
      transitions: transitions,
      confirmers: _FakeConfirmerRepository(),
      lastWords: _FakeLastWordRepository(),
      sessions: InMemoryConfirmerSessionStore(),
      notifications: notifications,
      profiles: _FakeProfileRepository(),
      caseStore: links,
    );

    final discovered = (await repository.listOwners()).single;
    expect(discovered.owner.name, '보내는 사람');
    expect(discovered.tasks.single.id, 'task-1');
    expect(discovered.letters.single.title, '남긴 말');
    notifications.items = [];
    expect((await repository.listOwners()).single.tasks.single.id, 'task-1');
    expect(await links.read('other-user'), isEmpty);
  });
}

class _FakeTransitionRepository extends TransitionRepository {
  _FakeTransitionRepository() : super(Dio());

  List<DesignatingUser> owners = [
    const DesignatingUser(id: 'owner-1', name: '보내는 사람'),
  ];
  List<AccountHandlingTask> tasks = [];

  @override
  Future<List<ConfirmerAccess>> claimAccess() async => [];

  @override
  Future<List<DesignatingUser>> listDesignatingUsers() async => owners;

  @override
  Future<List<AccountHandlingTask>> listTasks(String caseId) async => tasks;
}

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository() : super(Dio());
  List<AppNotification> items = [];

  @override
  Future<List<AppNotification>> list() async => items;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(Dio());

  @override
  Future<Profile> fetch() async =>
      const Profile(id: 'user-1', name: '받는 사람', email: 'me@example.com');
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
