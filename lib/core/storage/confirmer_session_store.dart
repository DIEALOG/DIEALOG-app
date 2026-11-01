import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/confirmer_access.dart';

abstract interface class ConfirmerSessionStore {
  Future<List<ConfirmerSession>> read();
  Future<void> upsert(ConfirmerSession session);
  Future<void> remove(String confirmerId);
}

class SecureConfirmerSessionStore implements ConfirmerSessionStore {
  SecureConfirmerSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'confirmer_sessions';
  final FlutterSecureStorage _storage;

  @override
  Future<List<ConfirmerSession>> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) ConfirmerSession.fromJson(item),
      ].where((session) => !session.expired).toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  @override
  Future<void> upsert(ConfirmerSession session) async {
    final sessions = await read()
      ..removeWhere((item) => item.confirmerId == session.confirmerId);
    sessions.add(session);
    await _storage.write(
      key: _key,
      value: jsonEncode([for (final item in sessions) item.toJson()]),
    );
  }

  @override
  Future<void> remove(String confirmerId) async {
    final sessions = await read()
      ..removeWhere((item) => item.confirmerId == confirmerId);
    await _storage.write(
      key: _key,
      value: jsonEncode([for (final item in sessions) item.toJson()]),
    );
  }
}

class InMemoryConfirmerSessionStore implements ConfirmerSessionStore {
  final _sessions = <ConfirmerSession>[];

  @override
  Future<List<ConfirmerSession>> read() async =>
      _sessions.where((session) => !session.expired).toList();

  @override
  Future<void> upsert(ConfirmerSession session) async {
    _sessions.removeWhere((item) => item.confirmerId == session.confirmerId);
    _sessions.add(session);
  }

  @override
  Future<void> remove(String confirmerId) async =>
      _sessions.removeWhere((item) => item.confirmerId == confirmerId);
}
