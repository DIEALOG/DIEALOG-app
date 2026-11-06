import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/confirmer_access.dart';
import '../../data/models/designating_user.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/transition_case.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_providers.dart';
import 'invitation_screen.dart';

class ConfirmerInbox {
  const ConfirmerInbox(this.session, this.cases, this.error);
  final ConfirmerSession session;
  final List<TransitionCase> cases;
  final String? error;
}

final designatingUsersProvider =
    FutureProvider.autoDispose<List<DesignatingUser>>(
      (ref) => ref.watch(authControllerProvider) == AuthStatus.signedIn
          ? ref.watch(transitionRepositoryProvider).listDesignatingUsers()
          : Future.value(const <DesignatingUser>[]),
    );

final confirmerInboxProvider = FutureProvider.autoDispose<List<ConfirmerInbox>>(
  (ref) async {
    final store = ref.watch(confirmerSessionStoreProvider);
    final savedSessions = await store.read();
    if (ref.watch(authControllerProvider) == AuthStatus.signedIn &&
        savedSessions.isEmpty) {
      try {
        final claimed = await ref
            .watch(transitionRepositoryProvider)
            .claimAccess();
        for (final access in claimed) {
          final fresh = ConfirmerSession.fromAccess(access);
          final previous = (await store.read())
              .where((item) => item.confirmerId == fresh.confirmerId)
              .firstOrNull;
          await store.upsert(
            previous == null ? fresh : fresh.withCaseIds(previous.knownCaseIds),
          );
        }
      } on ApiException {
        // Older servers have no claim endpoint; local sessions still apply.
      }
    }
    final sessions = await store.read();
    final repository = ref.watch(confirmerRepositoryProvider);
    return Future.wait([
      for (final session in sessions)
        () async {
          try {
            final cases = await repository.listCases(session.authToken);
            if (cases.isNotEmpty) {
              await store.upsert(
                session.withCaseIds(cases.map((item) => item.id)),
              );
            }
            return ConfirmerInbox(session, cases, null);
          } on ApiException catch (error) {
            return ConfirmerInbox(session, const [], error.userMessage);
          }
        }(),
    ]);
  },
);

class ConfirmerCasesScreen extends ConsumerWidget {
  const ConfirmerCasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(confirmerInboxProvider);
    final signedIn = ref.watch(authControllerProvider) == AuthStatus.signedIn;
    final owners = ref.watch(designatingUsersProvider);
    final notifications = signedIn ? ref.watch(notificationsProvider) : null;
    return Scaffold(
      appBar: AppBar(title: const Text('내게 온 요청'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait<Object>([
            if (signedIn) ref.refresh(designatingUsersProvider.future),
            ref.refresh(confirmerInboxProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text('내게 온 요청', style: AppText.screenTitle),
            const SizedBox(height: 20),
            Text('확인할 요청', style: AppText.section),
            inbox.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(confirmerInboxProvider),
                child: const Text('요청을 불러오지 못했어요. 다시 시도'),
              ),
              data: (entries) {
                final active = [
                  for (final entry in entries)
                    for (final item in entry.cases)
                      if (item.status == TransitionCaseStatus.pendingConfirmation ||
                          item.status == TransitionCaseStatus.waitingPeriod)
                        (entry, item),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (active.isEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        signedIn
                            ? '확인할 요청이 없어요.'
                            : '로그인하면 내게 온 요청을 볼 수 있어요.',
                        style: AppText.body,
                      ),
                      for (final entry in entries)
                        if (entry.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(entry.error!,
                                style: const TextStyle(color: AppColors.unread)),
                          ),
                    ],
                    for (final (entry, item) in active)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${_ownerName(owners.asData?.value, entry.session)}님의 사후 전환',
                          style: AppText.listTitle,
                        ),
                        subtitle: Text(
                          '${item.status.label} · ${_date(item.requestedAt)}',
                          style: AppText.listCaption,
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.muted),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ConfirmerCaseDetailScreen(
                                session: entry.session,
                                caseId: item.id,
                                initialCase: item,
                                ownerName: _ownerName(
                                    owners.asData?.value, entry.session),
                              ),
                            ),
                          );
                          ref.invalidate(confirmerInboxProvider);
                        },
                      ),
                  ],
                );
              },
            ),
            if (inbox.asData?.value.every((entry) => entry.cases.isEmpty) ==
                true) ...[
              const SizedBox(height: 24),
              if (signedIn) ...[
                Text('받은 초대', style: AppText.section),
                if (notifications case AsyncData<List<AppNotification>>(
                  :final value,
                ))
                  for (final notice in value.where((item) =>
                      item.eventType == 'confirmer_invitation' &&
                      item.invitationToken != null))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(notice.message, style: AppText.listTitle),
                      subtitle: Text(
                        inbox.asData?.value.any((entry) =>
                                  entry.session.confirmerId ==
                                  notice.metadata['confirmer_id']) ==
                                true
                            ? '수락한 요청 확인'
                            : '초대 수락',
                        style: AppText.listCaption,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => InvitationScreen(
                              initialToken: notice.invitationToken,
                              notificationId: notice.id,
                              confirmerId:
                                  notice.metadata['confirmer_id'] as String?,
                            ),
                          ),
                        );
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(confirmerInboxProvider);
                        ref.invalidate(designatingUsersProvider);
                      },
                    ),
              ],
              OutlinedButton(
                onPressed: () async {
                  await context.push(Routes.invitation);
                  ref.invalidate(confirmerInboxProvider);
                  ref.invalidate(designatingUsersProvider);
                },
                child: const Text('초대 코드 입력'),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


}

String _ownerName(List<DesignatingUser>? owners, ConfirmerSession session) {
  for (final owner in owners ?? const <DesignatingUser>[]) {
    if (owner.id == session.ownerUserId && owner.name.isNotEmpty) {
      return owner.name;
    }
  }
  return '소유자';
}

class ConfirmerCaseDetailScreen extends ConsumerStatefulWidget {
  const ConfirmerCaseDetailScreen({
    super.key,
    required this.session,
    required this.caseId,
    required this.ownerName,
    this.initialCase,
  });

  final ConfirmerSession session;
  final String caseId;
  final String ownerName;
  final TransitionCase? initialCase;

  @override
  ConsumerState<ConfirmerCaseDetailScreen> createState() =>
      _ConfirmerCaseDetailScreenState();
}

class _ConfirmerCaseDetailScreenState
    extends ConsumerState<ConfirmerCaseDetailScreen> {
  late Future<_ConfirmerCaseView> _case = _reload();
  bool _busy = false;
  String? _error;
  TransitionDecision? _decision;
  bool _firstLoad = true;

  Future<_ConfirmerCaseView> _reload() async {
    final store = ref.read(confirmerSessionStoreProvider);
    final saved = (await store.read())
        .where((item) => item.confirmerId == widget.session.confirmerId)
        .firstOrNull;
    await store.upsert((saved ?? widget.session).withCaseIds([widget.caseId]));
    final token = saved?.authToken ?? widget.session.authToken;
    final repository = ref.read(confirmerRepositoryProvider);
    final fallback = _firstLoad ? widget.initialCase : null;
    _firstLoad = false;
    TransitionCase item;
    try {
      item = await repository.getCase(token, widget.caseId);
    } on ApiException {
      if (fallback == null) rethrow;
      item = fallback;
    }
    TransitionDecision? ownDecision;
    try {
      final responses = await repository.listConfirmations(
        token,
        widget.caseId,
      );
      for (final response in responses) {
        if (response.confirmerId == widget.session.confirmerId) {
          ownDecision = response.decision;
          break;
        }
      }
    } on ApiException {
      // The case remains usable if its response history cannot be fetched.
    }
    return _ConfirmerCaseView(item, ownDecision);
  }

  Future<void> _submit(TransitionDecision decision) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(decision.label),
        content: const Text('제출한 확인 결과는 전환 절차에 반영됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('제출'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = (await ref.read(confirmerSessionStoreProvider).read())
          .where((item) => item.confirmerId == widget.session.confirmerId)
          .firstOrNull;
      final response = await ref
          .read(confirmerRepositoryProvider)
          .confirm(
            saved?.authToken ?? widget.session.authToken,
            widget.caseId,
            decision,
          );
      ref.invalidate(confirmerInboxProvider);
      if (mounted) {
        setState(() {
          _decision = response.decision;
          _case = _reload();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('사후 전환 확인'), centerTitle: true),
    body: FutureBuilder<_ConfirmerCaseView>(
      future: _case,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _case = _reload()),
                child: const Text('상태를 불러오지 못했어요. 다시 시도'),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final item = snapshot.data!.item;
        final ownDecision = snapshot.data!.ownDecision ?? _decision;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  Text(
                    '${widget.ownerName}님의 사후 전환',
                    style: AppText.screenTitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '요청 내용이 사실인지 확인해 주세요. '
                    '확인자 동의가 모이면 공개 대기로 바뀝니다.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: 28),
                  _InfoRow('현재 상태', item.status.label),
                  _InfoRow(
                    '전환 기준',
                    '확인자 ${item.minimumConfirmers}명 동의 + '
                        '${item.waitingPeriodDays}일 대기',
                  ),
                  _InfoRow('요청일', _date(item.requestedAt)),
                  if (item.eligibleAt != null)
                    _InfoRow('공개 가능일', _date(item.eligibleAt!)),
                  if (item.reason?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    Text('요청 사유', style: AppText.section),
                    const SizedBox(height: 6),
                    Text(item.reason!, style: AppText.paragraph),
                  ],
                  if (item.awaitingAutoConfirm) ...[
                    const SizedBox(height: 16),
                    Text('대기 기간이 끝났어요. 곧 사후 공개로 바뀝니다.', style: AppText.helper),
                  ],
                  if (ownDecision != null) ...[
                    const SizedBox(height: 20),
                    Text('내 응답: ${ownDecision.label}', style: AppText.section),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.unread),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (item.canConfirm)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _busy
                                ? null
                                : () => _submit(TransitionDecision.disagree),
                            child: const Text('사실이 아니에요'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          label: '사실이 맞아요',
                          height: 48,
                          busy: _busy,
                          onPressed: _busy
                              ? null
                              : () => _submit(TransitionDecision.agree),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ConfirmerCaseView {
  const _ConfirmerCaseView(this.item, this.ownDecision);

  final TransitionCase item;
  final TransitionDecision? ownDecision;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        SizedBox(width: 84, child: Text(label, style: AppText.listCaption)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppText.body.copyWith(color: AppColors.ink),
          ),
        ),
      ],
    ),
  );
}

String _date(DateTime date) =>
    '${date.toLocal().year}년 ${date.toLocal().month}월 ${date.toLocal().day}일';
