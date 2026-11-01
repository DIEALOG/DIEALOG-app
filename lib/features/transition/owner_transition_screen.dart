import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/alive_check.dart';
import '../../data/models/transition_case.dart';
import '../../data/providers.dart';

class OwnerTransitionOverview {
  const OwnerTransitionOverview(this.cases, this.checks);
  final List<TransitionCase> cases;
  final List<AliveCheck> checks;
}

final ownerTransitionProvider =
    FutureProvider.autoDispose<OwnerTransitionOverview>((ref) async {
      final repository = ref.watch(transitionRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.listCases(),
        repository.listAliveChecks(),
      ]);
      return OwnerTransitionOverview(
        results[0] as List<TransitionCase>,
        results[1] as List<AliveCheck>,
      );
    });

class OwnerTransitionScreen extends ConsumerWidget {
  const OwnerTransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(ownerTransitionProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('사후 전환 상태', style: AppText.screenTitle),
            ),
            Expanded(
              child: overview.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(ownerTransitionProvider),
                    child: Text(_message(error, '상태를 불러오지 못했어요. 다시 시도')),
                  ),
                ),
                data: (data) => RefreshIndicator(
                  onRefresh: () => ref.refresh(ownerTransitionProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    children: [
                      Text('생존 확인', style: AppText.section),
                      const SizedBox(height: 8),
                      Text('정해진 주기에 맞춰 생존 여부를 확인합니다.', style: AppText.body),
                      if (data.checks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text('예약된 일정이 없어요.', style: AppText.body),
                        ),
                      for (final check in data.checks.take(5))
                        _AliveCheckRow(check: check),
                      if (data.checks.isEmpty)
                        TextButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(transitionRepositoryProvider)
                                  .scheduleAliveCheck();
                              ref.invalidate(ownerTransitionProvider);
                            } catch (error) {
                              if (context.mounted) _showError(context, error);
                            }
                          },
                          child: const Text('다음 생존 확인 예약'),
                        ),
                      const SizedBox(height: 30),
                      Text('전환 절차', style: AppText.section),
                      const SizedBox(height: 8),
                      if (data.cases.isEmpty)
                        Text('시작된 전환 절차가 없어요.', style: AppText.body),
                      for (final item in data.cases)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.status.label,
                            style: AppText.listTitle,
                          ),
                          subtitle: Text(
                            '요청일 ${_date(item.requestedAt)}',
                            style: AppText.listCaption,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.chevron,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OwnerCaseScreen(caseId: item.id),
                              ),
                            );
                            ref.invalidate(ownerTransitionProvider);
                          },
                        ),
                      const SizedBox(height: 16),
                      Text('전환 요청은 초대를 수락한 확인자가 시작합니다.', style: AppText.helper),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AliveCheckRow extends ConsumerStatefulWidget {
  const _AliveCheckRow({required this.check});
  final AliveCheck check;

  @override
  ConsumerState<_AliveCheckRow> createState() => _AliveCheckRowState();
}

class _AliveCheckRowState extends ConsumerState<_AliveCheckRow> {
  bool busy = false;

  Future<void> _respond() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('생존 확인에 응답할까요?'),
        content: const Text('응답하면 현재 일정이 완료되고 다음 일정이 예약됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('응답하기'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(transitionRepositoryProvider)
          .respondAliveCheck(widget.check.id);
      ref.invalidate(ownerTransitionProvider);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.listDivider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.check.sequence}회차 · ${widget.check.status.label}',
                style: AppText.listTitle,
              ),
              const SizedBox(height: 4),
              Text(
                '예정 ${_date(widget.check.scheduledAt)} · 마감 ${_date(widget.check.dueAt)}',
                style: AppText.listCaption,
              ),
            ],
          ),
        ),
        if (widget.check.canRespond)
          TextButton(
            onPressed: busy ? null : _respond,
            child: Text('응답', style: AppText.headerAction),
          ),
      ],
    ),
  );
}

class OwnerCaseScreen extends ConsumerStatefulWidget {
  const OwnerCaseScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<OwnerCaseScreen> createState() => _OwnerCaseScreenState();
}

class _OwnerCaseScreenState extends ConsumerState<OwnerCaseScreen> {
  late Future<(TransitionCase, List<TransitionConfirmation>)> detail = _load();
  bool busy = false;

  Future<(TransitionCase, List<TransitionConfirmation>)> _load() async {
    final repository = ref.read(transitionRepositoryProvider);
    final item = await repository.getCase(widget.caseId);
    final confirmations = await repository.listConfirmations(widget.caseId);
    return (item, confirmations);
  }

  Future<void> _cancel() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('전환 절차를 취소할까요?'),
        content: const Text('진행 중인 사후 전환 확인이 중단됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('돌아가기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(transitionRepositoryProvider).cancelCase(widget.caseId);
      setState(() => detail = _load());
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(onBack: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text('전환 절차 상세', style: AppText.screenTitle),
          ),
          Expanded(
            child:
                FutureBuilder<(TransitionCase, List<TransitionConfirmation>)>(
                  future: detail,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: TextButton(
                          onPressed: () => setState(() => detail = _load()),
                          child: Text(
                            _message(
                              snapshot.error!,
                              '상세 내용을 불러오지 못했어요. 다시 시도',
                            ),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final (item, confirmations) = snapshot.data!;
                    final agreed = confirmations
                        .where(
                          (entry) => entry.decision == TransitionDecision.agree,
                        )
                        .length;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      children: [
                        _DetailRow('진행 상태', item.status.label),
                        _DetailRow('요청일', _date(item.requestedAt)),
                        _DetailRow(
                          '확인자 동의',
                          '$agreed / ${item.minimumConfirmers}명',
                        ),
                        _DetailRow('대기 기간', '${item.waitingPeriodDays}일'),
                        if (item.eligibleAt != null)
                          _DetailRow('전환 가능일', _date(item.eligibleAt!)),
                        const SizedBox(height: 28),
                        Text('확인 결과', style: AppText.section),
                        if (confirmations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text('아직 제출된 결과가 없어요.', style: AppText.body),
                          ),
                        for (var i = 0; i < confirmations.length; i++)
                          _DetailRow(
                            '확인자 ${i + 1}',
                            confirmations[i].decision.label,
                          ),
                        if (item.canCancel) ...[
                          const SizedBox(height: 32),
                          OutlinedButton(
                            onPressed: busy ? null : _cancel,
                            child: const Text('전환 절차 취소'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.listDivider)),
    ),
    child: Row(
      children: [
        Text(label, style: AppText.body),
        const Spacer(),
        Text(value, style: AppText.listTitle),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

String _message(Object error, String fallback) =>
    error is ApiException ? error.message : fallback;

void _showError(BuildContext context, Object error) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(_message(error, '요청을 처리하지 못했어요.'))));
