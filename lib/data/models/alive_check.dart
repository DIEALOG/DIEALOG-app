import 'json.dart';

enum AliveCheckStatus {
  scheduled('scheduled', '예정'),
  pending('pending', '응답 필요'),
  responded('responded', '응답 완료'),
  overdue('overdue', '기한 초과'),
  cancelled('cancelled', '취소됨'),
  unknown('', '상태 확인 필요');

  const AliveCheckStatus(this.wire, this.label);
  final String wire;
  final String label;

  static AliveCheckStatus fromWire(Object? value) =>
      values.firstWhere((item) => item.wire == value, orElse: () => unknown);
}

class AliveCheck {
  const AliveCheck({
    required this.id,
    required this.sequence,
    required this.status,
    required this.scheduledAt,
    required this.dueAt,
    this.respondedAt,
  });

  factory AliveCheck.fromJson(Json json) => AliveCheck(
    id: json['id'] as String? ?? '',
    sequence: json['sequence'] as int? ?? 0,
    status: AliveCheckStatus.fromWire(json['status']),
    scheduledAt:
        parseDate(json['scheduled_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    dueAt: parseDate(json['due_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    respondedAt: parseDate(json['responded_at']),
  );

  final String id;
  final int sequence;
  final AliveCheckStatus status;
  final DateTime scheduledAt;
  final DateTime dueAt;
  final DateTime? respondedAt;

  bool get canRespond =>
      status == AliveCheckStatus.scheduled ||
      status == AliveCheckStatus.pending ||
      status == AliveCheckStatus.overdue;
}
