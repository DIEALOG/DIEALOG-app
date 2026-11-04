import '../../core/network/api_exception.dart';
import '../../core/storage/confirmer_session_store.dart';
import '../../core/storage/entrusted_case_store.dart';
import '../models/account_handling_task.dart';
import '../models/app_notification.dart';
import '../models/confirmer_access.dart';
import '../models/designating_user.dart';
import '../models/last_word.dart';
import '../models/transition_case.dart';
import 'confirmer_repository.dart';
import 'last_word_repository.dart';
import 'notification_repository.dart';
import 'profile_repository.dart';
import 'transition_repository.dart';

/// One owner's records as seen by the signed-in stakeholder.
class EntrustedOwner {
  const EntrustedOwner({
    required this.owner,
    required this.tasks,
    required this.letters,
    this.activeCase,
    this.error,
  });

  final DesignatingUser owner;

  /// Account handling tasks this login may act on. The server already filters
  /// to the accounts naming me, so anything here is mine to handle.
  final List<AccountHandlingTask> tasks;

  /// Letters this owner addressed to me. Empty until their records open.
  final List<LastWord> letters;

  /// Set while a transition request is still being confirmed or waiting.
  final TransitionCase? activeCase;

  /// Why this owner's section could not be loaded, if it failed.
  final String? error;

  int get doneCount =>
      tasks.where((t) => t.status == AccountHandlingStatus.completed).length;

  bool get hasAnything =>
      tasks.isNotEmpty || letters.isNotEmpty || activeCase != null;
}

/// Everything the 사후 · 맡은 기록 side needs for the signed-in user.
///
/// A stakeholder reaches an owner's records through three hops: the confirmer
/// credentials tied to their login, the transition case that opened, and the
/// per-account tasks the server scopes to them.
class EntrustedRepository {
  const EntrustedRepository({
    required this.transitions,
    required this.confirmers,
    required this.lastWords,
    required this.sessions,
    required this.notifications,
    required this.profiles,
    required this.caseStore,
  });

  final TransitionRepository transitions;
  final ConfirmerRepository confirmers;
  final LastWordRepository lastWords;
  final ConfirmerSessionStore sessions;
  final NotificationRepository notifications;
  final ProfileRepository profiles;
  final EntrustedCaseStore caseStore;

  /// Keep the routing IDs before a notification is read or deleted. The store
  /// is keyed by the signed-in user, never shared across accounts on a device.
  Future<void> rememberNotifications(List<AppNotification> items) async {
    final profile = await profiles.fetch();
    await _remember(profile.id, items);
  }

  Future<void> _remember(String userId, List<AppNotification> items) =>
      caseStore.merge(userId, [
        for (final item in items)
          if (item.eventType == 'transition_confirmed' &&
              (item.receiverId.isEmpty || item.receiverId == userId))
            if (item.metadata['target_user_id'] is String &&
                item.metadata['case_id'] is String)
              EntrustedCaseLink(
                ownerId: item.metadata['target_user_id'] as String,
                ownerName: item.metadata['target_user_name'] is String
                    ? item.metadata['target_user_name'] as String
                    : '',
                caseId: item.metadata['case_id'] as String,
              ),
      ]);

  /// Links any invitation that matches this login, so a reinstall still finds
  /// the owners who named this person. Older servers answer 404.
  Future<List<ConfirmerSession>> syncSessions() async {
    final stored = await sessions.read();
    try {
      for (final access in await transitions.claimAccess()) {
        final fresh = ConfirmerSession.fromAccess(access);
        final previous = stored
            .where((s) => s.confirmerId == fresh.confirmerId)
            .firstOrNull;
        await sessions.upsert(
          previous == null ? fresh : fresh.withCaseIds(previous.knownCaseIds),
        );
      }
    } on ApiException {
      // Nothing to claim, or the endpoint is missing; keep what is stored.
    }
    return sessions.read();
  }

  Future<List<EntrustedOwner>> listOwners() async {
    final profile = await profiles.fetch();
    final sessions = await syncSessions();
    // A stakeholder who was not a confirmer still receives a confirmed-case
    // notification. Keep its IDs after the notification is deleted.
    try {
      await _remember(profile.id, await notifications.list());
    } on ApiException {
      // Saved links and confirmer sessions remain usable while notifications
      // cannot be fetched.
    }
    final links = await caseStore.read(profile.id);
    List<DesignatingUser> designating;
    try {
      designating = await transitions.listDesignatingUsers();
    } on ApiException {
      if (links.isEmpty) rethrow;
      designating = [];
    }
    final byOwner = {for (final owner in designating) owner.id: owner};
    for (final link in links) {
      byOwner.putIfAbsent(
        link.ownerId,
        () => DesignatingUser(
          id: link.ownerId,
          name: link.ownerName.isNotEmpty ? link.ownerName : '보낸 사람',
        ),
      );
    }
    return Future.wait([
      for (final owner in byOwner.values)
        _loadOwner(owner, sessions, [
          for (final link in links)
            if (link.ownerId == owner.id) link,
        ]),
    ]);
  }

  Future<EntrustedOwner> _loadOwner(
    DesignatingUser owner,
    List<ConfirmerSession> linked,
    List<EntrustedCaseLink> remembered,
  ) async {
    final session = linked.where((s) => s.ownerUserId == owner.id).firstOrNull;
    try {
      final caseIds = <String>{
        ...?session?.knownCaseIds,
        for (final link in remembered) link.caseId,
      };
      TransitionCase? active;

      if (session != null) {
        try {
          for (final item in await confirmers.listCases(session.authToken)) {
            caseIds.add(item.id);
            if (item.status != TransitionCaseStatus.confirmed) active ??= item;
          }
        } on ApiException {
          // A renewed login may outlive the old confirmer token. Saved case ids
          // can still be read with the signed-in stakeholder's bearer token.
        }
        if (caseIds.length != session.knownCaseIds.length) {
          await sessions.upsert(session.withCaseIds(caseIds));
        }
      }

      final tasks = <AccountHandlingTask>[];
      var opened = remembered.isNotEmpty;
      for (final caseId in caseIds) {
        if (session != null) {
          try {
            final detail = await confirmers.getCase(session.authToken, caseId);
            opened |= detail.status == TransitionCaseStatus.confirmed;
            if (detail.status != TransitionCaseStatus.confirmed &&
                detail.status != TransitionCaseStatus.cancelled) {
              active = detail;
            }
          } on ApiException {
            // A stale confirmer token does not revoke stakeholder access.
          }
        }
        try {
          tasks.addAll(await transitions.listTasks(caseId));
        } on ApiException {
          // A cancelled or foreign case: skip it rather than fail the owner.
        }
      }
      tasks.sort((a, b) => a.id.compareTo(b.id));
      // The recipient endpoint currently does not check transition state.
      // Do not reveal an owner's private letter before the server confirms it.
      final letters = opened || tasks.isNotEmpty
          ? await lastWords.listAddressedToMe(owner.id)
          : <LastWord>[];

      return EntrustedOwner(
        owner: owner,
        tasks: tasks,
        letters: letters,
        activeCase: active,
      );
    } on ApiException catch (e) {
      return EntrustedOwner(
        owner: owner,
        tasks: const [],
        letters: const [],
        error: e.userMessage,
      );
    }
  }

  /// Issues the handling code for [taskId]. The response is the only place the
  /// code appears, so the caller has to show it right away.
  Future<AccountHandlingRequestResponse> requestCode(String taskId) =>
      transitions.requestTask(taskId);
}
