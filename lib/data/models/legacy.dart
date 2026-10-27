import 'account.dart';
import 'json.dart';

/// `domain.LegacyResponse`: a named bundle of accounts.
///
/// The list endpoint returns a bare JSON array, so there is no pagination.
class Legacy {
  const Legacy({
    required this.id,
    required this.name,
    this.accounts = const [],
    this.userId,
    this.createdAt,
  });

  factory Legacy.fromJson(Json json) => Legacy(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        accounts: parseList(json['accounts'], Account.fromJson),
        userId: json['user_id'] as String?,
        createdAt: parseDate(json['created_at']),
      );

  final String id;
  final String name;
  final List<Account> accounts;
  final String? userId;
  final DateTime? createdAt;
}
