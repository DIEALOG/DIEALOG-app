import 'json.dart';

enum ConfirmerStatus {
  pending,
  accepted,
  declined,
  revoked,
  expired,
  unknown;

  static ConfirmerStatus fromWire(String? value) => values.firstWhere(
    (status) => status.name == value,
    orElse: () => ConfirmerStatus.unknown,
  );
}

class TransitionConfirmer {
  const TransitionConfirmer({
    required this.id,
    required this.name,
    required this.status,
    this.stakeholderId,
    this.email,
    this.phone,
  });

  factory TransitionConfirmer.fromJson(Json json) => TransitionConfirmer(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    status: ConfirmerStatus.fromWire(json['status'] as String?),
    stakeholderId: json['stakeholder_id'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );

  final String id;
  final String name;
  final ConfirmerStatus status;
  final String? stakeholderId;
  final String? email;
  final String? phone;

  bool get isActive =>
      status == ConfirmerStatus.pending || status == ConfirmerStatus.accepted;
}

/// The invitation token is returned only at issuance, never by listConfirmers.
class TransitionInvitation {
  const TransitionInvitation({
    required this.confirmer,
    required this.token,
    required this.expiresAt,
  });

  factory TransitionInvitation.fromJson(Json json) => TransitionInvitation(
    confirmer: TransitionConfirmer.fromJson(json['confirmer'] as Json),
    token: json['invitation_token'] as String? ?? '',
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );

  final TransitionConfirmer confirmer;
  final String token;
  final DateTime expiresAt;
}
