import 'account.dart';
import 'json.dart';

enum AccountHandlingStatus {
  pending('pending', '요청 전'),
  inProgress('in_progress', '처리 중'),
  completed('completed', '처리 완료'),
  failed('failed', '처리 실패'),
  skipped('skipped', '처리 제외'),
  unknown('', '상태 확인 필요');

  const AccountHandlingStatus(this.wire, this.label);
  final String wire;
  final String label;

  static AccountHandlingStatus fromWire(Object? value) =>
      values.firstWhere((item) => item.wire == value, orElse: () => unknown);
}

class AccountHandlingTask {
  const AccountHandlingTask({
    required this.id,
    required this.caseId,
    required this.accountId,
    required this.status,
    required this.action,
    required this.requestCount,
    this.actionMessage,
    this.failureReason,
  });

  factory AccountHandlingTask.fromJson(Json json) {
    return AccountHandlingTask(
      id: json['id'] as String? ?? '',
      caseId: json['transition_case_id'] as String? ?? '',
      accountId: json['account_id'] as String? ?? '',
      status: AccountHandlingStatus.fromWire(json['status']),
      action: AccountActionKind.fromWire(json['action_snapshot']),
      actionMessage: json['action_message_snapshot'] as String?,
      requestCount: json['request_count'] as int? ?? 0,
      failureReason: json['failure_reason'] as String?,
    );
  }

  final String id;
  final String caseId;
  final String accountId;
  final AccountHandlingStatus status;
  final AccountActionKind action;
  final String? actionMessage;
  final int requestCount;
  final String? failureReason;

  bool get canRequest =>
      status == AccountHandlingStatus.pending ||
      status == AccountHandlingStatus.inProgress ||
      status == AccountHandlingStatus.failed;
}

class AccountHandlingRequest {
  const AccountHandlingRequest({
    required this.name,
    required this.token,
    required this.expiresAt,
    this.email,
    this.phone,
  });

  factory AccountHandlingRequest.fromJson(Json json) => AccountHandlingRequest(
    name: json['name'] as String? ?? '',
    token: json['token'] as String? ?? '',
    expiresAt:
        parseDate(json['expires_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );

  final String name;
  final String token;
  final DateTime expiresAt;
  final String? email;
  final String? phone;
}

class AccountHandlingRequestResponse {
  const AccountHandlingRequestResponse(this.task, this.requests);

  factory AccountHandlingRequestResponse.fromJson(Json json) =>
      AccountHandlingRequestResponse(
        AccountHandlingTask.fromJson(json['task'] as Json),
        parseList(json['requests'], AccountHandlingRequest.fromJson),
      );

  final AccountHandlingTask task;
  final List<AccountHandlingRequest> requests;
}
