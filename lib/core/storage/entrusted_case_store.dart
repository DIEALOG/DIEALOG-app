import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A confirmed transition found in this user's notifications. Only routing
/// identifiers are cached; account credentials always come from the server.
class EntrustedCaseLink {
  const EntrustedCaseLink({
    required this.ownerId,
    required this.ownerName,
    required this.caseId,
  });

  final String ownerId;
  final String ownerName;
  final String caseId;

  Map<String, String> toJson() => {
    'owner_id': ownerId,
    'owner_name': ownerName,
    'case_id': caseId,
  };

  static EntrustedCaseLink? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final ownerId = value['owner_id'];
    final caseId = value['case_id'];
    if (ownerId is! String ||
        ownerId.isEmpty ||
        caseId is! String ||
        caseId.isEmpty) {
      return null;
    }
    return EntrustedCaseLink(
      ownerId: ownerId,
      ownerName: value['owner_name'] is String
          ? value['owner_name'] as String
          : '',
      caseId: caseId,
    );
  }
}

abstract interface class EntrustedCaseStore {
  Future<List<EntrustedCaseLink>> read(String userId);
  Future<void> merge(String userId, Iterable<EntrustedCaseLink> links);
}

class SecureEntrustedCaseStore implements EntrustedCaseStore {
  SecureEntrustedCaseStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String userId) => 'entrusted_cases_$userId';

  @override
  Future<List<EntrustedCaseLink>> read(String userId) async {
    if (userId.isEmpty) return [];
    final raw = await _storage.read(key: _key(userId));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [for (final item in decoded) ?EntrustedCaseLink.fromJson(item)];
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> merge(String userId, Iterable<EntrustedCaseLink> links) async {
    if (userId.isEmpty) return;
    final byCase = {for (final link in await read(userId)) link.caseId: link};
    for (final link in links) {
      if (link.ownerId.isEmpty || link.caseId.isEmpty) continue;
      byCase[link.caseId] = link;
    }
    await _storage.write(
      key: _key(userId),
      value: jsonEncode([for (final link in byCase.values) link.toJson()]),
    );
  }
}

class InMemoryEntrustedCaseStore implements EntrustedCaseStore {
  final _byUser = <String, Map<String, EntrustedCaseLink>>{};

  @override
  Future<List<EntrustedCaseLink>> read(String userId) async =>
      _byUser[userId]?.values.toList() ?? [];

  @override
  Future<void> merge(String userId, Iterable<EntrustedCaseLink> links) async {
    final byCase = _byUser.putIfAbsent(userId, () => {});
    for (final link in links) {
      if (link.ownerId.isNotEmpty && link.caseId.isNotEmpty) {
        byCase[link.caseId] = link;
      }
    }
  }
}
