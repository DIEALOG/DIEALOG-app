import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/confirmer_access.dart';
import '../../data/models/designating_user.dart';
import '../../data/models/transition_case.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';

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
    if (ref.watch(authControllerProvider) == AuthStatus.signedIn) {
      try {
        final claimed = await ref
            .watch(transitionRepositoryProvider)
            .claimAccess();
        for (final access in claimed) {
          await store.upsert(ConfirmerSession.fromAccess(access));
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
            return ConfirmerInbox(
              session,
              await repository.listCases(session.authToken),
              null,
            );
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
            const SizedBox(height: 10),
            Text(
              '나를 확인자로 지정한 사람과, 사실 확인이 필요한 요청을 여기서 봐요.',
              style: AppText.body,
            ),
            if (signedIn) ...[
              const SizedBox(height: 24),
              Text('받은 초대', style: AppText.section),
              owners.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error is ApiException
                        ? error.userMessage
                        : '지정한 사람을 불러오지 못했어요.',
                    style: AppText.body,
                  ),
                ),
                data: (people) => people.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '아직 나를 확인자로 지정한 사람이 없어요.',
                          style: AppText.body,
                        ),
                      )
                    : Column(
                        children: [
                          for (final person in people)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                person.name,
                                style: AppText.listTitle,
                              ),
                              subtitle: Text(
                                '로그인 계정으로 확인자 자격이 연결됩니다.',
                                style: AppText.listCaption,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
            const SizedBox(height: 20),
            Text('확인할 요청', style: AppText.section),
            inbox.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () => ref.invalidate(confirmerInboxProvider),
                  child: const Text('요청을 불러오지 못했어요. 다시 시도'),
                ),
              ),
              data: (entries) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        signedIn
                            ? '진행 중인 확인 요청이 없어요.'
                            : '로그인하면 내게 온 확인 요청을 볼 수 있어요.',
                        style: AppText.body,
                      ),
                    ),
                  for (final entry in entries) ...[
                    const SizedBox(height: 20),
                    Text(
                      '확인자 · ${entry.session.name}',
                      style: AppText.section,
                    ),
                    if (entry.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          entry.error!,
                          style: const TextStyle(color: AppColors.unread),
                        ),
                      ),
                    if (entry.error == null && entry.cases.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('진행 중인 요청이 없어요.', style: AppText.body),
                      ),
                    for (final item in entry.cases)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('사후 전환 확인', style: AppText.listTitle),
                        subtitle: Text(
                          '${item.status.label} · ${_date(item.requestedAt)}',
                          style: AppText.listCaption,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.muted,
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ConfirmerCaseDetailScreen(
                                session: entry.session,
                                caseId: item.id,
                              ),
                            ),
                          );
                          ref.invalidate(confirmerInboxProvider);
                        },
                      ),
                    if (entry.error == null && entry.cases.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: () =>
                              _startCase(context, ref, entry.session),
                          child: const Text('사후 전환 확인 요청하기'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '확인자 자격은 초대를 받은 계정에 연결됩니다. '
              '요청만으로 사후 공개가 확정되지는 않아요.',
              style: AppText.helper,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCase(
    BuildContext context,
    WidgetRef ref,
    ConfirmerSession session,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('사후 전환 확인을 요청할까요?'),
        content: const Text(
          '이 확인자 자격이 연결된 사람의 사후 전환 절차가 '
          '시작됩니다. 실제 사실을 확인한 뒤 진행해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('요청하기'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    try {
      final item = await ref
          .read(confirmerRepositoryProvider)
          .startCase(session.authToken);
      ref.invalidate(confirmerInboxProvider);
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ConfirmerCaseDetailScreen(session: session, caseId: item.id),
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.userMessage)));
        if (error.message.toLowerCase().contains('already exists')) {
          ref.invalidate(confirmerInboxProvider);
        }
      }
    }
  }
}

class ConfirmerCaseDetailScreen extends ConsumerStatefulWidget {
  const ConfirmerCaseDetailScreen({
    super.key,
    required this.session,
    required this.caseId,
  });

  final ConfirmerSession session;
  final String caseId;

  @override
  ConsumerState<ConfirmerCaseDetailScreen> createState() =>
      _ConfirmerCaseDetailScreenState();
}

class _ConfirmerCaseDetailScreenState
    extends ConsumerState<ConfirmerCaseDetailScreen> {
  late Future<TransitionCase> _case = _reload();
  bool _busy = false;
  String? _error;
  TransitionDecision? _decision;

  Future<TransitionCase> _reload() => ref
      .read(confirmerRepositoryProvider)
      .getCase(widget.session.authToken, widget.caseId);

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
      await ref
          .read(confirmerRepositoryProvider)
          .confirm(widget.session.authToken, widget.caseId, decision);
      ref.invalidate(confirmerInboxProvider);
      if (mounted) {
        setState(() {
          _decision = decision;
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
    body: FutureBuilder<TransitionCase>(
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
        final item = snapshot.data!;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  Text('사후 전환 요청을 확인해 주세요', style: AppText.screenTitle),
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
                  if (_decision != null) ...[
                    const SizedBox(height: 20),
                    Text('내 응답: ${_decision!.label}', style: AppText.section),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.unread),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    '확인자는 전환 여부만 확인합니다. '
                    '데이터와 남기는 말은 지정된 사람만 볼 수 있어요.',
                    style: AppText.helper,
                  ),
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
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _submit(TransitionDecision.disagree),
                          child: const Text('사실이 아니에요'),
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
