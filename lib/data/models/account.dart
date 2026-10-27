import 'json.dart';
import 'stakeholder.dart';

/// `domain.AccountTypeField`: the external service an account lives on.
enum AccountService {
  google('Google', 'Google'),
  facebook('Facebook', 'Facebook'),
  twitter('Twitter', 'Twitter'),
  apple('Apple', 'Apple'),
  discord('Discord', 'Discord'),
  microsoft('Microsoft', 'Microsoft'),
  kakaoTalk('KakaoTalk', '카카오톡'),
  gitHub('GitHub', 'GitHub'),
  telegram('Telegram', 'Telegram'),
  instagram('Instagram', 'Instagram'),
  other('Other', '기타');

  const AccountService(this.wire, this.label);

  final String wire;

  /// Shown in the service heading of the data list.
  final String label;

  static AccountService fromWire(Object? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => other);
}

/// `domain.AccountActionField`: what should happen to the account after death.
enum AccountActionKind {
  delete('delete', '삭제'),
  remain('remain', '유지'),
  permissionMove('permission-move', '권한 이전'),
  backupAndDelete('backup-and-delete', '백업 후 삭제'),
  other('other', '직접 작성');

  const AccountActionKind(this.wire, this.label);

  final String wire;
  final String label;

  static AccountActionKind fromWire(Object? value) =>
      values.firstWhere((a) => a.wire == value, orElse: () => other);
}

class AccountType {
  const AccountType({required this.service, this.id, this.name});

  factory AccountType.fromJson(Json json) => AccountType(
        id: json['id'] as String?,
        name: json['name'] as String?,
        service: AccountService.fromWire(json['type']),
      );

  final String? id;

  /// Free-form service name, required when [service] is [AccountService.other].
  final String? name;
  final AccountService service;

  /// Heading shown above the account rows.
  String get label => service == AccountService.other && (name?.isNotEmpty ?? false)
      ? name!
      : service.label;

  Json toJson() => compact({'name': name, 'type': service.wire});
}

class AccountAction {
  const AccountAction({required this.kind, this.id, this.message});

  factory AccountAction.fromJson(Json json) => AccountAction(
        id: json['id'] as String?,
        kind: AccountActionKind.fromWire(json['action']),
        message: json['message'] as String?,
      );

  final String? id;
  final AccountActionKind kind;

  /// Free-form instruction for the stakeholders handling the account.
  final String? message;

  String get label => kind == AccountActionKind.other && (message?.isNotEmpty ?? false)
      ? message!
      : kind.label;

  Json toJson() => compact({'action': kind.wire, 'message': message});
}

/// `domain.AccountDetailResponse` / `domain.AccountListResponse`.
///
/// List responses carry only the stakeholder ids; detail responses carry the
/// stakeholders themselves plus the credentials.
class Account {
  const Account({
    required this.name,
    this.id = '',
    this.legacyId,
    this.type,
    this.action,
    this.accountId,
    this.accountPassword,
    this.dataLocation,
    this.stakeholderIds = const [],
    this.stakeholders = const [],
    this.stakeholderGroupIds = const [],
    this.stakeholderGroups = const [],
    this.createdAt,
  });

  factory Account.fromJson(Json json) => Account(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        legacyId: json['legacy_id'] as String?,
        type: json['type'] is Json
            ? AccountType.fromJson(json['type'] as Json)
            : null,
        action: json['action'] is Json
            ? AccountAction.fromJson(json['action'] as Json)
            : null,
        accountId: json['account_id'] as String?,
        accountPassword: json['account_password'] as String?,
        dataLocation: json['data_location'] as String?,
        stakeholderIds: parseStrings(json['stakeholder_ids']),
        stakeholders: parseList(json['stakeholders'], Stakeholder.fromJson),
        stakeholderGroupIds: parseStrings(json['stakeholder_group_ids']),
        stakeholderGroups:
            parseList(json['stakeholder_groups'], StakeholderGroup.fromJson),
        createdAt: parseDate(json['created_at']),
      );

  final String id;
  final String? legacyId;

  /// Item name inside the service, e.g. `개인 계정`.
  final String name;
  final AccountType? type;
  final AccountAction? action;

  /// Login id on the external service.
  final String? accountId;
  final String? accountPassword;
  final String? dataLocation;

  /// Stakeholders the account is disclosed to after death.
  final List<String> stakeholderIds;
  final List<Stakeholder> stakeholders;
  final List<String> stakeholderGroupIds;
  final List<StakeholderGroup> stakeholderGroups;
  final DateTime? createdAt;

  /// Ids of everyone the account opens to, counting group members once.
  Set<String> get disclosedTo => {
        ...stakeholderIds,
        for (final s in stakeholders) s.id,
        for (final g in stakeholderGroups) ...[
          ...g.stakeholderIds,
          for (final s in g.stakeholders) s.id,
        ],
      }..removeWhere((id) => id.isEmpty);

  bool get hasAudience =>
      disclosedTo.isNotEmpty || stakeholderGroupIds.isNotEmpty;

  Account copyWith({
    String? name,
    AccountType? type,
    AccountAction? action,
    String? accountId,
    String? accountPassword,
    String? dataLocation,
    List<String>? stakeholderIds,
    List<String>? stakeholderGroupIds,
  }) =>
      Account(
        id: id,
        legacyId: legacyId,
        name: name ?? this.name,
        type: type ?? this.type,
        action: action ?? this.action,
        accountId: accountId ?? this.accountId,
        accountPassword: accountPassword ?? this.accountPassword,
        dataLocation: dataLocation ?? this.dataLocation,
        stakeholderIds: stakeholderIds ?? this.stakeholderIds,
        stakeholders: stakeholders,
        stakeholderGroupIds: stakeholderGroupIds ?? this.stakeholderGroupIds,
        stakeholderGroups: stakeholderGroups,
        createdAt: createdAt,
      );

  /// Request body for `POST /legacy/protected/{id}/account`.
  Json toJson() => compact({
        'name': name,
        'type': type?.toJson(),
        'action': action?.toJson(),
        'account_id': accountId,
        'account_password': accountPassword,
        'data_location': dataLocation,
        'stakeholder_ids': stakeholderIds.isEmpty ? null : stakeholderIds,
        'stakeholder_group_ids':
            stakeholderGroupIds.isEmpty ? null : stakeholderGroupIds,
      });
}
