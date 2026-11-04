import 'package:diealog_app/data/models/transition_case.dart';
import 'package:flutter_test/flutter_test.dart';

TransitionCase _case({
  required String status,
  DateTime? eligibleAt,
  String? reason,
}) => TransitionCase.fromJson({
  'id': 'case-1',
  'user_id': 'owner-1',
  'status': status,
  'minimum_confirmers_snapshot': 2,
  'waiting_period_days_snapshot': 7,
  'requested_at': '2026-11-01T00:00:00Z',
  'eligible_at': eligibleAt?.toUtc().toIso8601String(),
  'reason': reason,
});

void main() {
  test('the request reason round-trips from the server', () {
    expect(
      _case(status: 'pending_confirmation', reason: '병원에서 임종 확인').reason,
      '병원에서 임종 확인',
    );
    expect(_case(status: 'pending_confirmation').reason, isNull);
  });

  test('a waiting case past its eligible time is awaiting the 5-minute cron', () {
    final due = _case(
      status: 'waiting_period',
      eligibleAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(due.awaitingAutoConfirm, isTrue);
    expect(due.canCancel, isTrue, reason: 'cancel stays open until it confirms');
  });

  test('a waiting case before its eligible time is not awaiting the cron', () {
    final early = _case(
      status: 'waiting_period',
      eligibleAt: DateTime.now().add(const Duration(days: 3)),
    );
    expect(early.awaitingAutoConfirm, isFalse);
  });

  test('cases outside the waiting period never claim auto-confirm', () {
    final past = DateTime.now().subtract(const Duration(days: 1));
    expect(
      _case(status: 'confirmed', eligibleAt: past).awaitingAutoConfirm,
      isFalse,
    );
    expect(
      _case(status: 'cancelled', eligibleAt: past).awaitingAutoConfirm,
      isFalse,
    );
    expect(
      _case(status: 'pending_confirmation').awaitingAutoConfirm,
      isFalse,
    );
  });
}
