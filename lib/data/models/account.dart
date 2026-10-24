import 'json.dart';
import 'stakeholder.dart';

/// `domain.AccountTypeField`
enum AccountService {
  google('Google'),
  facebook('Facebook'),
  twitter('Twitter'),
  apple('Apple'),
  discord('Discord'),
  microsoft('Microsoft'),
  kakaoTalk('KakaoTalk'),
  gitHub('GitHub'),
  telegram('Telegram'),
  instagram('Instagram'),
  other('Other');

  const AccountService(this.wire);

  final String wire;

  static AccountService fromWire(Object? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => other);
}

/// `domain.AccountActionField`: what should happen to the account after death.
enum AccountActionKind {
  delete('delete'),
  remain('remain'),
  permissionMove('permission-move'),
  backupAndDelete('backup-and-delete'),
  other('other');

  const AccountActionKind(this.wire);

  final String wire;

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

  /// Free-form service name, used when [service] is [AccountService.other].
  final String? name;
  final AccountService service;

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
  final String? message;

  Json toJson() => compact({'action': kind.wire, 'message': message});
}

/// `domain.Account`: one service account inside a legacy.
class Account {
  const Account({
    this.id = '',
    this.legacyId,
    this.type,
    this.action,
    this.accountId,
    this.accountPassword,
    this.dataLocation,
    this.stakeholderIds = const [],
    this.stakeholders = const [],
    this.createdAt,
  });

  factory Account.fromJson(Json json) => Account(
        id: json['id'] as String? ?? '',
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
        createdAt: parseDate(json['created_at']),
      );

  final String id;
  final String? legacyId;
  final AccountType? type;
  final AccountAction? action;

  /// Login id on the external service.
  final String? accountId;
  final String? accountPassword;
  final String? dataLocation;

  /// Stakeholders the account is disclosed to after death.
  final List<String> stakeholderIds;
  final List<Stakeholder> stakeholders;
  final DateTime? createdAt;

  /// Request body for `POST /legacy/protected/{id}/account`.
  Json toJson() => compact({
        'type': type?.toJson(),
        'action': action?.toJson(),
        'account_id': accountId,
        'account_password': accountPassword,
        'data_location': dataLocation,
        'stakeholder_ids': stakeholderIds,
      });
}
