import 'json.dart';
import 'stakeholder.dart';

/// `domain.Profile`
class Profile {
  const Profile({
    required this.email,
    required this.name,
    this.testament,
    this.stakeholders = const [],
  });

  factory Profile.fromJson(Json json) => Profile(
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        testament: json['testament'] as String?,
        stakeholders: parseList(json['stakeholders'], Stakeholder.fromJson),
      );

  final String email;
  final String name;

  /// Free-form will text ("남기는 말").
  final String? testament;
  final List<Stakeholder> stakeholders;
}
