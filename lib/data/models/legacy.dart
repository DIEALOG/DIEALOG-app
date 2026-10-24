import 'account.dart';
import 'json.dart';

/// `domain.Legacy`: a named bundle of accounts ("데이터" in the app).
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

/// `handler.PaginatedLegacyResponse`
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory Paginated.fromJson(Json json, T Function(Json) fromJson) {
    final items = parseList(json['items'], fromJson);
    return Paginated(
      items: items,
      total: json['total'] as int? ?? items.length,
      limit: json['limit'] as int? ?? items.length,
      offset: json['offset'] as int? ?? 0,
    );
  }

  final List<T> items;
  final int total;
  final int limit;
  final int offset;

  bool get hasMore => offset + items.length < total;
}
