import 'json.dart';
import 'transition_confirmer.dart';

class ConfirmerAccess {
  const ConfirmerAccess({
    required this.confirmer,
    required this.authToken,
    required this.expiresAt,
  });

  factory ConfirmerAccess.fromJson(Json json) => ConfirmerAccess(
    confirmer: TransitionConfirmer.fromJson(json['confirmer'] as Json),
    authToken: json['auth_token'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );

  final TransitionConfirmer confirmer;
  final String authToken;
  final DateTime expiresAt;
}

class ConfirmerSession {
  const ConfirmerSession({
    required this.confirmerId,
    required this.ownerUserId,
    required this.name,
    required this.authToken,
    required this.expiresAt,
  });

  factory ConfirmerSession.fromAccess(ConfirmerAccess value) =>
      ConfirmerSession(
        confirmerId: value.confirmer.id,
        ownerUserId: value.confirmer.ownerUserId ?? '',
        name: value.confirmer.name,
        authToken: value.authToken,
        expiresAt: value.expiresAt,
      );

  factory ConfirmerSession.fromJson(Json json) => ConfirmerSession(
    confirmerId: json['confirmer_id'] as String,
    ownerUserId: json['owner_user_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    authToken: json['auth_token'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );

  final String confirmerId;
  final String ownerUserId;
  final String name;
  final String authToken;
  final DateTime expiresAt;

  bool get expired => !expiresAt.isAfter(DateTime.now());

  Json toJson() => {
    'confirmer_id': confirmerId,
    'owner_user_id': ownerUserId,
    'name': name,
    'auth_token': authToken,
    'expires_at': expiresAt.toIso8601String(),
  };
}
