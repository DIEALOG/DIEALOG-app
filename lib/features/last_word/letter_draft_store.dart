import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LetterDraft {
  const LetterDraft({
    required this.title,
    required this.message,
    required this.receiverIds,
    required this.receiverGroupIds,
    required this.savedAt,
  });

  factory LetterDraft.fromJson(Map<String, dynamic> json) => LetterDraft(
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    receiverIds:
        (json['receiver_ids'] as List?)?.whereType<String>().toList() ?? [],
    receiverGroupIds:
        (json['receiver_group_ids'] as List?)?.whereType<String>().toList() ??
        [],
    savedAt:
        DateTime.tryParse(json['saved_at'] as String? ?? '') ?? DateTime.now(),
  );

  final String title;
  final String message;
  final List<String> receiverIds;
  final List<String> receiverGroupIds;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'receiver_ids': receiverIds,
    'receiver_group_ids': receiverGroupIds,
    'saved_at': savedAt.toIso8601String(),
  };
}

abstract interface class LetterDraftStore {
  Future<LetterDraft?> read(String userId, String letterId);
  Future<void> write(String userId, String letterId, LetterDraft draft);
  Future<void> delete(String userId, String letterId);
}

class SecureLetterDraftStore implements LetterDraftStore {
  const SecureLetterDraftStore(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String userId, String letterId) =>
      'letter-draft:$userId:$letterId';

  @override
  Future<LetterDraft?> read(String userId, String letterId) async {
    final raw = await _storage.read(key: _key(userId, letterId));
    if (raw == null) return null;
    try {
      return LetterDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(String userId, String letterId, LetterDraft draft) =>
      _storage.write(
        key: _key(userId, letterId),
        value: jsonEncode(draft.toJson()),
      );

  @override
  Future<void> delete(String userId, String letterId) =>
      _storage.delete(key: _key(userId, letterId));
}
