import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/account_handling_task.dart';
import '../../data/models/last_word.dart';
import '../../data/providers.dart';
import '../../data/repositories/entrusted_repository.dart';
import '../home/greeting.dart';
import 'handling_code_sheet.dart';

final entrustedOwnersProvider =
    FutureProvider.autoDispose<List<EntrustedOwner>>(
      (ref) => ref.watch(entrustedRepositoryProvider).listOwners(),
    );

/// 15: everything a stakeholder was entrusted with, grouped by owner.
class AfterlifeScreen extends ConsumerWidget {
  const AfterlifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owners = ref.watch(entrustedOwnersProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text('맡은 기록', style: AppText.screenTitle),
            ),
            Expanded(
              child: owners.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Failed(
                  message: error is ApiException
                      ? error.userMessage
                      : '기록을 불러오지 못했어요.',
                  onRetry: () => ref.invalidate(entrustedOwnersProvider),
                ),
                data: (items) {
                  final visible = [
                    for (final item in items)
                      if (item.hasAnything || item.error != null) item,
                  ];
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(entrustedOwnersProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              items.isEmpty
                                  ? '표시할 인계 기록을 찾지 못했어요.\n'
                                        '현재는 확인자로 연결된 사람의 기록을 조회할 수 있어요.'
                                  : '아직 공개된 기록이 없어요.\n'
                                        '사후 전환이 확정되면 여기에 나타나요.',
                              style: AppText.body,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final item in visible) _OwnerCard(item: item),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.item});

  final EntrustedOwner item;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntrustedOwnerScreen(ownerId: item.owner.id),
      ),
    ),
    child: Container(
      height: 75,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.listDivider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.inkDeep,
            child: Text(
              firstCharacter(item.owner.name),
              style: AppText.section.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.owner.name} 님의 기록', style: AppText.section),
                const SizedBox(height: 3),
                Text(
                  item.error ??
                      '맡은 데이터 ${item.tasks.length}개 · 받은 말 ${item.letters.length}통',
                  style: AppText.listCaption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
        ],
      ),
    ),
  );
}

/// 15 detail: one owner's tasks and letters.
class EntrustedOwnerScreen extends ConsumerWidget {
  const EntrustedOwnerScreen({super.key, required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owners = ref.watch(entrustedOwnersProvider);
    return Scaffold(
      body: SafeArea(
        child: owners.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Failed(
            message: error is ApiException ? error.userMessage : '불러오지 못했어요.',
            onRetry: () => ref.invalidate(entrustedOwnersProvider),
          ),
          data: (items) {
            final item = items.where((o) => o.owner.id == ownerId).firstOrNull;
            if (item == null) {
              return const Center(child: Text('기록을 찾을 수 없어요.'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(onBack: () => Navigator.of(context).pop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    '${item.owner.name} 님의 기록',
                    style: AppText.screenTitle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    item.tasks.isEmpty
                        ? (item.activeCase != null ? '사후 전환 확인 중' : '공개 대기 중')
                        : '${item.tasks.length}개 중 ${item.doneCount}개 완료',
                    style: AppText.listCaption,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(entrustedOwnersProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        if (item.letters.isNotEmpty) ...[
                          Text('나에게 남긴 말', style: AppText.section),
                          const SizedBox(height: 8),
                          for (final letter in item.letters)
                            _LetterRow(letter: letter, from: item.owner.name),
                          const SizedBox(height: 24),
                        ],
                        Text('맡은 데이터', style: AppText.section),
                        const SizedBox(height: 8),
                        if (item.tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text('아직 맡은 데이터가 없어요.', style: AppText.body),
                          ),
                        for (final task in item.tasks) _TaskRow(task: task),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final AccountHandlingTask task;

  Color get _statusColor => switch (task.status) {
    AccountHandlingStatus.completed => AppColors.progress,
    AccountHandlingStatus.failed => AppColors.unread,
    AccountHandlingStatus.inProgress => AppColors.inkDeep,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(task: task)),
    ),
    child: Container(
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
                Text(task.action.label, style: AppText.listTitle),
                const SizedBox(height: 3),
                Text(
                  task.actionMessage?.isNotEmpty == true
                      ? task.actionMessage!
                      : '상세 지침 없음',
                  style: AppText.listCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            task.status.label,
            style: AppText.listCaption.copyWith(color: _statusColor),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
        ],
      ),
    ),
  );
}

/// 16 / 17: one account's handling detail, code issuing and result reporting.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.task});

  final AccountHandlingTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var task = this.task;
    for (final owner
        in ref.watch(entrustedOwnersProvider).asData?.value ??
            const <EntrustedOwner>[]) {
      for (final updated in owner.tasks) {
        if (updated.id == task.id) task = updated;
      }
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  Text('처리 방식', style: AppText.listCaption),
                  const SizedBox(height: 4),
                  Text(task.action.label, style: AppText.screenTitle),
                  const SizedBox(height: 18),
                  if (task.actionMessage?.isNotEmpty == true) ...[
                    Text('상세 지침', style: AppText.listCaption),
                    const SizedBox(height: 6),
                    Text(task.actionMessage!, style: AppText.paragraph),
                    const SizedBox(height: 22),
                  ],
                  Text('처리 현황', style: AppText.section),
                  const SizedBox(height: 6),
                  Text(task.status.label, style: AppText.listTitle),
                  if (task.failureReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.failureReason!,
                      style: AppText.helper.copyWith(color: AppColors.unread),
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (final person in task.assignees)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(person.name, style: AppText.body),
                          ),
                          Text(person.status.label, style: AppText.listCaption),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text('계정 정보', style: AppText.section),
                  const SizedBox(height: 6),
                  Text(
                    '계정 아이디와 비밀번호는 아직 담당자에게 열리지 않아요. '
                    '서버에 담당자용 조회 권한이 추가되어야 볼 수 있어요.',
                    style: AppText.helper,
                  ),
                  const SizedBox(height: 22),
                  Text('처리 기록', style: AppText.section),
                  const SizedBox(height: 6),
                  if (task.events.isEmpty)
                    Text('아직 처리 기록이 없어요.', style: AppText.helper)
                  else
                    for (final event in task.events)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(event.label, style: AppText.body),
                            ),
                            if (event.createdAt != null)
                              Text(
                                _date(event.createdAt!),
                                style: AppText.listCaption,
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            if (task.canRequest)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _IssueCodeButton(task: task),
              ),
          ],
        ),
      ),
    );
  }
}

class _IssueCodeButton extends ConsumerStatefulWidget {
  const _IssueCodeButton({required this.task});

  final AccountHandlingTask task;

  @override
  ConsumerState<_IssueCodeButton> createState() => _IssueCodeButtonState();
}

class _IssueCodeButtonState extends ConsumerState<_IssueCodeButton> {
  var _busy = false;

  Future<void> _issue() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final profile = await ref.read(profileRepositoryProvider).fetch();
      final result = await ref
          .read(entrustedRepositoryProvider)
          .requestCode(widget.task.id);
      ref.invalidate(entrustedOwnersProvider);
      if (!mounted) return;
      final mine = result.requests
          .where(
            (request) =>
                _sameEmail(request.email, profile.email) ||
                _samePhone(request.phone, profile.phoneNumber),
          )
          .toList();
      if (result.requests.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('새로 발급할 처리 코드가 없어요.')),
        );
      } else if (mine.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('로그인 계정과 담당자 연락처가 일치하지 않아요. 관계자 정보를 확인해 주세요.'),
          ),
        );
      } else {
        await showHandlingCodeSheet(
          context,
          mine,
          onSubmitted: () => ref.invalidate(entrustedOwnersProvider),
        );
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.userMessage)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('처리 코드를 발급하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      onPressed: _busy ? null : _issue,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.white,
              ),
            )
          : Text(
              '처리 코드 받기',
              style: AppText.button.copyWith(color: AppColors.white),
            ),
    ),
  );
}

/// 18: a letter the owner addressed to this login.
class _LetterRow extends StatelessWidget {
  const _LetterRow({required this.letter, required this.from});

  final LastWord letter;
  final String from;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceivedLetterScreen(letter: letter, from: from),
      ),
    ),
    child: Container(
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
                Text(letter.title, style: AppText.listTitle),
                const SizedBox(height: 3),
                Text(
                  letter.message,
                  style: AppText.listCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
        ],
      ),
    ),
  );
}

class ReceivedLetterScreen extends StatelessWidget {
  const ReceivedLetterScreen({
    super.key,
    required this.letter,
    required this.from,
  });

  final LastWord letter;
  final String from;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                Text('$from 님이 남긴 말', style: AppText.listCaption),
                const SizedBox(height: 6),
                Text(letter.title, style: AppText.screenTitle),
                const SizedBox(height: 20),
                Text(letter.message, style: AppText.paragraph),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppText.body, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.month}월 ${local.day}일';
}

bool _sameEmail(String? left, String? right) =>
    left != null &&
    right != null &&
    left.isNotEmpty &&
    left.toLowerCase() == right.toLowerCase();

bool _samePhone(String? left, String? right) {
  final a = left?.replaceAll(RegExp(r'\D'), '') ?? '';
  final b = right?.replaceAll(RegExp(r'\D'), '') ?? '';
  return a.isNotEmpty && a == b;
}
