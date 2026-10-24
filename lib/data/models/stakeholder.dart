import 'json.dart';

/// `domain.Stakeholder`: a person who receives records or messages.
class Stakeholder {
  const Stakeholder({
    required this.name,
    this.id = '',
    this.email,
    this.phone,
    this.relationship,
    this.message,
    this.groupIds = const [],
    this.groups = const [],
    this.userId,
    this.createdAt,
  });

  factory Stakeholder.fromJson(Json json) => Stakeholder(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        relationship: json['relationship'] as String?,
        message: json['message'] as String?,
        groupIds: parseStrings(json['group_ids']),
        groups: parseList(json['groups'], StakeholderGroup.fromJson),
        userId: json['user_id'] as String?,
        createdAt: parseDate(json['created_at']),
      );

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? relationship;

  /// Message left for this person.
  final String? message;
  final List<String> groupIds;
  final List<StakeholderGroup> groups;
  final String? userId;
  final DateTime? createdAt;

  Json toJson() => compact({
        'name': name,
        'email': email,
        'phone': phone,
        'relationship': relationship,
        'message': message,
        'group_ids': groupIds,
      });
}

/// `domain.StakeholderGroup`
class StakeholderGroup {
  const StakeholderGroup({
    required this.name,
    this.id = '',
    this.stakeholderIds = const [],
    this.stakeholders = const [],
    this.userId,
    this.createdAt,
  });

  factory StakeholderGroup.fromJson(Json json) => StakeholderGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        stakeholderIds: parseStrings(json['stakeholder_ids']),
        stakeholders: parseList(json['stakeholders'], Stakeholder.fromJson),
        userId: json['user_id'] as String?,
        createdAt: parseDate(json['created_at']),
      );

  final String id;
  final String name;
  final List<String> stakeholderIds;
  final List<Stakeholder> stakeholders;
  final String? userId;
  final DateTime? createdAt;

  Json toJson() => {'name': name, 'stakeholder_ids': stakeholderIds};
}
