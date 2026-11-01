import 'package:diealog_app/core/storage/local_prefs.dart';
import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/models/transition_confirmer.dart';
import 'package:diealog_app/data/models/transition_policy.dart';
import 'package:diealog_app/data/repositories/transition_repository.dart';
import 'package:diealog_app/features/settings/settings_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

TransitionConfirmer _confirmer(String id, ConfirmerStatus status) =>
    TransitionConfirmer(
      id: id,
      name: id,
      status: status,
      stakeholderId: 's-$id',
    );

ConfirmerBoard _board(List<TransitionConfirmer> confirmers, {int minimum = 2}) =>
    ConfirmerBoard(
      confirmers: confirmers,
      people: const [],
      policy: TransitionPolicy(minimumConfirmers: minimum),
    );

void main() {
  test('pending invites do not count toward the minimum', () {
    final board = _board([
      _confirmer('a', ConfirmerStatus.accepted),
      _confirmer('b', ConfirmerStatus.accepted),
      _confirmer('c', ConfirmerStatus.pending),
      _confirmer('d', ConfirmerStatus.revoked),
    ]);

    expect(board.acceptedCount, 2);
    // Revoked confirmers drop off the list entirely.
    expect(board.active.length, 3);
  });

  test('revoking is blocked once the accepted count hits the minimum', () {
    final atMinimum = _board([
      _confirmer('a', ConfirmerStatus.accepted),
      _confirmer('b', ConfirmerStatus.accepted),
      _confirmer('c', ConfirmerStatus.pending),
    ]);
    expect(atMinimum.canRevoke(_confirmer('a', ConfirmerStatus.accepted)),
        isFalse);
    // A pending invite can always be withdrawn.
    expect(
      atMinimum.canRevoke(_confirmer('c', ConfirmerStatus.pending)),
      isTrue,
    );

    final spare = _board([
      _confirmer('a', ConfirmerStatus.accepted),
      _confirmer('b', ConfirmerStatus.accepted),
      _confirmer('c', ConfirmerStatus.accepted),
    ]);
    expect(spare.canRevoke(_confirmer('a', ConfirmerStatus.accepted)), isTrue);
  });

  test('someone already invited cannot be picked again', () {
    const person = Stakeholder(id: 's-a', name: '이도윤');
    final board = ConfirmerBoard(
      confirmers: [_confirmer('a', ConfirmerStatus.pending)],
      people: const [person, Stakeholder(id: 's-z', name: '김정희')],
      policy: const TransitionPolicy(),
    );

    expect(board.isAssigned(person), isTrue);
    expect(board.isAssigned(const Stakeholder(id: 's-z', name: '김정희')),
        isFalse);
  });

  test('patching the interval leaves the other policy fields alone', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final transitions = TransitionRepository(dio);

    final before = await transitions.fetchPolicy();
    final after = await transitions.updatePolicy(aliveCheckIntervalDays: 180);

    expect(after.aliveCheckIntervalDays, 180);
    expect(after.minimumConfirmers, before.minimumConfirmers);
    expect(after.waitingPeriodDays, before.waitingPeriodDays);
    expect(after.summary, '확인자 ${before.minimumConfirmers}명 동의 '
        '+ ${before.waitingPeriodDays}일 대기');
    dio.close();
  });

  test('local settings round-trip and default notifications on', () async {
    final store = InMemoryLocalSettingsStore();
    expect((await store.read()).notifyTransitionRequest, isTrue);
    expect((await store.read()).lockByFaceId, isFalse);

    await store.write(
      const LocalSettings().copyWith(
        lockByFaceId: true,
        notifyLetterDraft: true,
      ),
    );
    final saved = await store.read();
    expect(saved.lockByFaceId, isTrue);
    expect(saved.notifyLetterDraft, isTrue);
    // Untouched fields keep their defaults.
    expect(saved.certifyBeforeSensitive, isFalse);
    expect(LocalSettings.fromJson(saved.toJson()).lockByFaceId, isTrue);
  });
}
