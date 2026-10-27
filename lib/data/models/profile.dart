import 'json.dart';
import 'stakeholder.dart';

/// `domain.Profile`
class Profile {
  const Profile({
    required this.email,
    required this.name,
    this.id = '',
    this.phoneNumber,
    this.profileImagePath,
    this.stakeholders = const [],
    this.stakeholderGroups = const [],
  });

  factory Profile.fromJson(Json json) => Profile(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phoneNumber: json['phone_number'] as String?,
        profileImagePath: json['profile_image_path'] as String?,
        stakeholders: parseList(json['stakeholders'], Stakeholder.fromJson),
        stakeholderGroups:
            parseList(json['stakeholder_groups'], StakeholderGroup.fromJson),
      );

  final String id;
  final String email;
  final String name;
  final String? phoneNumber;

  /// Server-relative path, served under `/public/...`.
  final String? profileImagePath;
  final List<Stakeholder> stakeholders;
  final List<StakeholderGroup> stakeholderGroups;
}

/// `domain.UserConfig`
class UserConfig {
  const UserConfig({
    this.lockByFaceId = false,
    this.certificationBeforeSensitiveInformation = false,
  });

  factory UserConfig.fromJson(Json json) => UserConfig(
        lockByFaceId: json['lock_by_face_id'] as bool? ?? false,
        certificationBeforeSensitiveInformation:
            json['certification_before_sensitive_information'] as bool? ?? false,
      );

  final bool lockByFaceId;
  final bool certificationBeforeSensitiveInformation;

  Json toJson() => {
        'lock_by_face_id': lockByFaceId,
        'certification_before_sensitive_information':
            certificationBeforeSensitiveInformation,
      };
}
