import 'json.dart';

/// `domain.TransitionDesignatingUser`
class DesignatingUser {
  const DesignatingUser({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.profileImagePath,
    this.createdAt,
  });

  factory DesignatingUser.fromJson(Json json) => DesignatingUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    phoneNumber: json['phone_number'] as String?,
    profileImagePath: json['profile_image_path'] as String?,
    createdAt: parseDate(json['created_at']),
  );

  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? profileImagePath;
  final DateTime? createdAt;
}
