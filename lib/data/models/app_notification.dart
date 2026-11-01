import 'json.dart';

enum NotificationKind {
  transition,
  legacy,
  invite,
  unknown;

  static NotificationKind fromWire(String? value) => switch (value) {
    'transition' => NotificationKind.transition,
    'legacy' => NotificationKind.legacy,
    'invite' => NotificationKind.invite,
    _ => NotificationKind.unknown,
  };
}

/// `domain.Notification`
class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.isRead,
    this.receiverId = '',
    this.kind = NotificationKind.unknown,
    this.metadata = const {},
    this.createdAt,
  });

  factory AppNotification.fromJson(Json json) => AppNotification(
    id: '${json['id'] ?? ''}',
    receiverId: json['receiver_id'] as String? ?? '',
    message: json['message'] as String? ?? '',
    isRead: json['is_read'] as bool? ?? false,
    kind: NotificationKind.fromWire(json['type'] as String?),
    metadata: json['metadata'] is Json
        ? Map<String, dynamic>.from(json['metadata'] as Json)
        : const {},
    createdAt: parseDate(json['created_at']),
  );

  final String id;
  final String receiverId;
  final String message;
  final bool isRead;
  final NotificationKind kind;
  final Json metadata;
  final DateTime? createdAt;

  String get eventType => metadata['type'] as String? ?? '';

  String? get invitationToken {
    final token = metadata['invitation_token'];
    return token is String && token.isNotEmpty ? token : null;
  }

  String get title => switch (eventType) {
    'confirmer_invitation' => '확인자 초대',
    'confirmer_invitation_accepted' => '확인자 초대 수락',
    'confirmer_invitation_declined' => '확인자 초대 거절',
    _ => switch (kind) {
      NotificationKind.transition => '사후 전환 요청',
      NotificationKind.legacy => '데이터',
      NotificationKind.invite => '확인자 초대',
      NotificationKind.unknown => '알림',
    },
  };

  String get caption => switch (eventType) {
    'confirmer_invitation' => '초대를 수락하면 사실 확인 역할을 맡게 돼요.',
    'confirmer_invitation_accepted' => '사후 전환 확인자 관리에서 확인할 수 있어요.',
    'confirmer_invitation_declined' => '확인자 초대 상태를 확인해 주세요.',
    _ => switch (kind) {
      NotificationKind.transition => '내게 온 요청에서 사실 여부를 확인해 주세요.',
      NotificationKind.legacy => '데이터 탭에서 확인할 수 있어요.',
      _ => '자세한 내용은 알림을 열어 확인해 주세요.',
    },
  };

  String get timeLabel {
    final date = createdAt?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (sameDay) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '오늘 $hour:$minute';
    }
    return '${date.month}월 ${date.day}일';
  }
}
