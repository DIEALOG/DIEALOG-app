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

/// `domain.AccountHandlingTaskAssigneeStatus`
enum AssigneeStatus {
  pending('pending', '대기'),
  confirmed('confirmed', '처리 완료'),
  failed('failed', '처리 불가'),
  cancelled('cancelled', '종료됨'),
  unknown('', '상태 확인 필요');

  const AssigneeStatus(this.wire, this.label);
  final String wire;
  final String label;

  static AssigneeStatus fromWire(Object? value) =>
      values.firstWhere((item) => item.wire == value, orElse: () => unknown);
}

/// One person asked to handle a task.
class TaskAssignee {
  const TaskAssignee({
    required this.id,
    required this.name,
    required this.status,
    this.stakeholderId,
    this.email,
    this.responseMessage,
    this.requestedAt,
    this.respondedAt,
  });

  factory TaskAssignee.fromJson(Json json) => TaskAssignee(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    status: AssigneeStatus.fromWire(json['status']),
    stakeholderId: json['stakeholder_id'] as String?,
    email: json['email'] as String?,
    responseMessage: json['response_message'] as String?,
    requestedAt: parseDate(json['requested_at']),
    respondedAt: parseDate(json['responded_at']),
  );

  final String id;
  final String name;
  final AssigneeStatus status;
  final String? stakeholderId;
  final String? email;
  final String? responseMessage;
  final DateTime? requestedAt;
  final DateTime? respondedAt;
}

/// `domain.AccountHandlingEvent`, shown as the 처리 기록 timeline.
class HandlingEvent {
  const HandlingEvent({required this.type, this.message, this.createdAt});

  factory HandlingEvent.fromJson(Json json) => HandlingEvent(
    type: json['event_type'] as String? ?? '',
    message: json['message'] as String?,
    createdAt: parseDate(json['created_at']),
  );

  static const _labels = {
    'task_created': '처리 작업이 만들어졌어요',
    'request_issued': '처리 코드를 발급했어요',
    'stakeholder_confirmed': '처리 완료로 보고됐어요',
    'stakeholder_reported_failure': '처리 불가로 보고됐어요',
    'task_completed': '처리가 완료됐어요',
    'task_failed': '처리가 실패로 끝났어요',
  };

  final String type;
  final String? message;
  final DateTime? createdAt;

  String get label => _labels[type] ?? type;
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
    this.completedAt,
    this.assignees = const [],
    this.events = const [],
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
      completedAt: parseDate(json['completed_at']),
      assignees: parseList(json['assignees'], TaskAssignee.fromJson),
      events: parseList(json['events'], HandlingEvent.fromJson),
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
  final DateTime? completedAt;
  final List<TaskAssignee> assignees;
  final List<HandlingEvent> events;

  bool get canRequest =>
      status == AccountHandlingStatus.pending ||
      status == AccountHandlingStatus.inProgress ||
      status == AccountHandlingStatus.failed;

  /// The assignee row for [stakeholderIds], which are the ids this login holds
  /// in the owner's stakeholder list.
  TaskAssignee? assigneeFor(Set<String> stakeholderIds) {
    for (final a in assignees) {
      if (a.stakeholderId != null && stakeholderIds.contains(a.stakeholderId)) {
        return a;
      }
    }
    return null;
  }
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
