import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Switch states the server cannot report back.
///
/// The security pair is also sent to `PUT /profile/protected/config`, but
/// nothing returns it, so the device copy is what the screen shows. Push
/// delivery is still missing, so the notification switches stay local.
class LocalSettings {
  const LocalSettings({
    this.lockByFaceId = false,
    this.certifyBeforeSensitive = false,
    this.notifyTransitionRequest = true,
    this.notifyEntrustedProgress = true,
    this.notifyLetterDraft = false,
  });

  factory LocalSettings.fromJson(Map<String, dynamic> json) => LocalSettings(
    lockByFaceId: json['lock_by_face_id'] as bool? ?? false,
    certifyBeforeSensitive: json['certify_before_sensitive'] as bool? ?? false,
    notifyTransitionRequest:
        json['notify_transition_request'] as bool? ?? true,
    notifyEntrustedProgress:
        json['notify_entrusted_progress'] as bool? ?? true,
    notifyLetterDraft: json['notify_letter_draft'] as bool? ?? false,
  );

  final bool lockByFaceId;
  final bool certifyBeforeSensitive;
  final bool notifyTransitionRequest;
  final bool notifyEntrustedProgress;
  final bool notifyLetterDraft;

  LocalSettings copyWith({
    bool? lockByFaceId,
    bool? certifyBeforeSensitive,
    bool? notifyTransitionRequest,
    bool? notifyEntrustedProgress,
    bool? notifyLetterDraft,
  }) => LocalSettings(
    lockByFaceId: lockByFaceId ?? this.lockByFaceId,
    certifyBeforeSensitive:
        certifyBeforeSensitive ?? this.certifyBeforeSensitive,
    notifyTransitionRequest:
        notifyTransitionRequest ?? this.notifyTransitionRequest,
    notifyEntrustedProgress:
        notifyEntrustedProgress ?? this.notifyEntrustedProgress,
    notifyLetterDraft: notifyLetterDraft ?? this.notifyLetterDraft,
  );

  Map<String, dynamic> toJson() => {
    'lock_by_face_id': lockByFaceId,
    'certify_before_sensitive': certifyBeforeSensitive,
    'notify_transition_request': notifyTransitionRequest,
    'notify_entrusted_progress': notifyEntrustedProgress,
    'notify_letter_draft': notifyLetterDraft,
  };
}

abstract interface class LocalSettingsStore {
  Future<LocalSettings> read();
  Future<void> write(LocalSettings settings);
}

class SecureLocalSettingsStore implements LocalSettingsStore {
  SecureLocalSettingsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'local_settings';

  final FlutterSecureStorage _storage;

  @override
  Future<LocalSettings> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return const LocalSettings();
    try {
      return LocalSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const LocalSettings();
    }
  }

  @override
  Future<void> write(LocalSettings settings) =>
      _storage.write(key: _key, value: jsonEncode(settings.toJson()));
}

class InMemoryLocalSettingsStore implements LocalSettingsStore {
  LocalSettings _settings = const LocalSettings();

  @override
  Future<LocalSettings> read() async => _settings;

  @override
  Future<void> write(LocalSettings settings) async => _settings = settings;
}
