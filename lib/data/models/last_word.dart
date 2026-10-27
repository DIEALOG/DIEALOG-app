import 'json.dart';
import 'stakeholder.dart';

/// `domain.LastWord`: a message left for stakeholders ("남기는 말").
class LastWord {
  const LastWord({
    required this.title,
    required this.message,
    this.id = '',
    this.userId,
    this.receivers = const [],
    this.receiverGroups = const [],
    this.receiverIds = const [],
    this.receiverGroupIds = const [],
  });

  factory LastWord.fromJson(Json json) {
    final receivers = parseList(json['receiver'], Stakeholder.fromJson);
    final groups = parseList(json['receiver_groups'], StakeholderGroup.fromJson);
    return LastWord(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      receivers: receivers,
      receiverGroups: groups,
      receiverIds: [for (final r in receivers) r.id],
      receiverGroupIds: [for (final g in groups) g.id],
    );
  }

  final String id;
  final String? userId;
  final String title;
  final String message;
  final List<Stakeholder> receivers;
  final List<StakeholderGroup> receiverGroups;
  final List<String> receiverIds;
  final List<String> receiverGroupIds;

  /// Everyone the message reaches, counting group members once.
  Set<String> get audience => {
        ...receiverIds,
        for (final g in receiverGroups) ...[
          ...g.stakeholderIds,
          for (final s in g.stakeholders) s.id,
        ],
      }..removeWhere((id) => id.isEmpty);

  LastWord copyWith({
    String? title,
    String? message,
    List<String>? receiverIds,
    List<String>? receiverGroupIds,
  }) =>
      LastWord(
        id: id,
        userId: userId,
        title: title ?? this.title,
        message: message ?? this.message,
        receivers: receivers,
        receiverGroups: receiverGroups,
        receiverIds: receiverIds ?? this.receiverIds,
        receiverGroupIds: receiverGroupIds ?? this.receiverGroupIds,
      );

  /// Request body for `POST`/`PUT /last-word/protected`.
  Json toJson() => {
        'title': title,
        'message': message,
        'receiver_ids': receiverIds,
        'receiver_group_ids': receiverGroupIds,
      };
}
