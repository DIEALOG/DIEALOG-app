// MOCK: the backend has no after-death side yet ("사후 · 맡은 기록" screens):
// switching an owner to deceased, records entrusted to a stakeholder, and the
// messages they received. Shapes here are provisional until the API exists.

import '../../models/account.dart';

enum EntrustedRecordStatus { pending, done }

/// An account another user entrusted to me as their stakeholder.
class EntrustedRecord {
  const EntrustedRecord({
    required this.id,
    required this.ownerName,
    required this.legacyName,
    required this.account,
    required this.status,
    this.disclosedAt,
  });

  final String id;
  final String ownerName;
  final String legacyName;
  final Account account;
  final EntrustedRecordStatus status;
  final DateTime? disclosedAt;

  EntrustedRecord copyWith({EntrustedRecordStatus? status}) => EntrustedRecord(
        id: id,
        ownerName: ownerName,
        legacyName: legacyName,
        account: account,
        status: status ?? this.status,
        disclosedAt: disclosedAt,
      );
}

class ReceivedMessage {
  const ReceivedMessage({
    required this.id,
    required this.fromName,
    required this.message,
    this.receivedAt,
  });

  final String id;
  final String fromName;
  final String message;
  final DateTime? receivedAt;
}

abstract interface class AfterlifeRepository {
  /// Reports that [ownerEmail] has passed away, opening their records to
  /// stakeholders.
  Future<void> reportPassing(String ownerEmail);

  Future<List<EntrustedRecord>> listEntrusted();
  Future<EntrustedRecord> getEntrusted(String id);
  Future<EntrustedRecord> markHandled(String id);
  Future<List<ReceivedMessage>> listReceivedMessages();
}

class MockAfterlifeRepository implements AfterlifeRepository {
  static const _latency = Duration(milliseconds: 300);

  final List<EntrustedRecord> _records = [
    EntrustedRecord(
      id: 'mock-record-1',
      ownerName: '김하늘',
      legacyName: 'SNS 계정',
      account: const Account(
        id: 'mock-account-1',
        name: '개인 계정',
        type: AccountType(service: AccountService.instagram),
        action: AccountAction(
          kind: AccountActionKind.backupAndDelete,
          message: '사진은 백업해서 가족 앨범에 넣어 줘.',
        ),
        accountId: 'haneul.kim',
      ),
      status: EntrustedRecordStatus.pending,
      disclosedAt: DateTime(2026, 10, 1),
    ),
    EntrustedRecord(
      id: 'mock-record-2',
      ownerName: '김하늘',
      legacyName: '업무 계정',
      account: const Account(
        id: 'mock-account-2',
        name: '업무 계정',
        type: AccountType(service: AccountService.gitHub),
        action: AccountAction(kind: AccountActionKind.remain),
        accountId: 'haneul-dev',
      ),
      status: EntrustedRecordStatus.done,
      disclosedAt: DateTime(2026, 10, 1),
    ),
  ];

  final List<ReceivedMessage> _messages = [
    ReceivedMessage(
      id: 'mock-message-1',
      fromName: '김하늘',
      message: '그동안 고마웠어. 남은 일은 부탁할게.',
      receivedAt: DateTime(2026, 10, 1),
    ),
  ];

  @override
  Future<void> reportPassing(String ownerEmail) => Future.delayed(_latency);

  @override
  Future<List<EntrustedRecord>> listEntrusted() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_records);
  }

  @override
  Future<EntrustedRecord> getEntrusted(String id) async {
    await Future<void>.delayed(_latency);
    return _records.firstWhere((r) => r.id == id);
  }

  @override
  Future<EntrustedRecord> markHandled(String id) async {
    await Future<void>.delayed(_latency);
    final i = _records.indexWhere((r) => r.id == id);
    return _records[i] =
        _records[i].copyWith(status: EntrustedRecordStatus.done);
  }

  @override
  Future<List<ReceivedMessage>> listReceivedMessages() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_messages);
  }
}
