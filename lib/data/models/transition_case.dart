import 'json.dart';

enum TransitionCaseStatus {
  pendingConfirmation('pending_confirmation', '확인 중'),
  waitingPeriod('waiting_period', '공개 대기'),
  confirmed('confirmed', '사후 공개'),
  cancelled('cancelled', '취소됨'),
  unknown('', '상태 확인 필요');

  const TransitionCaseStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TransitionCaseStatus fromWire(Object? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => unknown,
  );
}

enum TransitionDecision {
  agree('agree', '사실이 맞아요'),
  disagree('disagree', '사실이 아니에요'),
  abstain('abstain', '판단 보류');

  const TransitionDecision(this.wire, this.label);
  final String wire;
  final String label;
}

class TransitionCase {
  const TransitionCase({
    required this.id,
    required this.userId,
    required this.status,
    required this.minimumConfirmers,
    required this.waitingPeriodDays,
    required this.requestedAt,
    this.waitingStartedAt,
    this.eligibleAt,
    this.confirmedAt,
    this.cancelledAt,
  });

  factory TransitionCase.fromJson(Json json) => TransitionCase(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    status: TransitionCaseStatus.fromWire(json['status']),
    minimumConfirmers: json['minimum_confirmers_snapshot'] as int? ?? 0,
    waitingPeriodDays: json['waiting_period_days_snapshot'] as int? ?? 0,
    requestedAt:
        DateTime.tryParse(json['requested_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    waitingStartedAt: DateTime.tryParse(
      json['waiting_started_at'] as String? ?? '',
    ),
    eligibleAt: DateTime.tryParse(json['eligible_at'] as String? ?? ''),
    confirmedAt: DateTime.tryParse(json['confirmed_at'] as String? ?? ''),
    cancelledAt: DateTime.tryParse(json['cancelled_at'] as String? ?? ''),
  );

  final String id;
  final String userId;
  final TransitionCaseStatus status;
  final int minimumConfirmers;
  final int waitingPeriodDays;
  final DateTime requestedAt;
  final DateTime? waitingStartedAt;
  final DateTime? eligibleAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;

  bool get canConfirm => status == TransitionCaseStatus.pendingConfirmation;
  bool get canCancel =>
      status == TransitionCaseStatus.pendingConfirmation ||
      status == TransitionCaseStatus.waitingPeriod;
}

class TransitionConfirmation {
  const TransitionConfirmation({
    required this.confirmerId,
    required this.decision,
    this.comment,
    this.respondedAt,
  });

  factory TransitionConfirmation.fromJson(Json json) => TransitionConfirmation(
    confirmerId: json['transition_confirmer_id'] as String? ?? '',
    decision: TransitionDecision.values.firstWhere(
      (item) => item.wire == json['decision'],
      orElse: () => TransitionDecision.abstain,
    ),
    comment: json['comment'] as String?,
    respondedAt: DateTime.tryParse(json['responded_at'] as String? ?? ''),
  );

  final String confirmerId;
  final TransitionDecision decision;
  final String? comment;
  final DateTime? respondedAt;
}
