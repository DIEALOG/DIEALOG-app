import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/account_handling_task.dart';
import '../../data/models/legacy.dart';
import '../../data/providers.dart';

class AccountTasksScreen extends ConsumerStatefulWidget {
  const AccountTasksScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<AccountTasksScreen> createState() => _AccountTasksScreenState();
}

class _AccountTasksScreenState extends ConsumerState<AccountTasksScreen> {
  late Future<(List<AccountHandlingTask>, List<Legacy>)> tasks = _load();
  String? busyId;

  Future<(List<AccountHandlingTask>, List<Legacy>)> _load() async {
    final results = await Future.wait<Object>([
      ref.read(transitionRepositoryProvider).listTasks(widget.caseId),
      ref.read(legacyRepositoryProvider).list(),
    ]);
    return (
      results[0] as List<AccountHandlingTask>,
      results[1] as List<Legacy>,
    );
  }

  Future<void> _request(AccountHandlingTask task) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('처리 코드를 발급할까요?'),
        content: const Text(
          '새 코드를 발급하면 이전에 받은 코드가 무효화될 수 있어요. '
          '발급된 코드는 이 화면에서만 볼 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('발급하기'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => busyId = task.id);
    try {
      final response = await ref
          .read(transitionRepositoryProvider)
          .requestTask(task.id);
      if (mounted) {
        if (response.requests.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('새로 전달할 코드가 없어요.')));
        } else {
          await _showCodes(context, response.requests);
        }
        setState(() => tasks = _load());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException ? error.message : '코드를 발급하지 못했어요.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busyId = null);
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
            child: Text('계정 처리 작업', style: AppText.screenTitle),
          ),
          Expanded(
            child: FutureBuilder<(List<AccountHandlingTask>, List<Legacy>)>(
              future: tasks,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(() => tasks = _load()),
                      child: const Text('작업을 불러오지 못했어요. 다시 시도'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final (items, legacies) = snapshot.data!;
                final accountNames = {
                  for (final legacy in legacies)
                    for (final account in legacy.accounts)
                      account.id: account.name,
                };
                return RefreshIndicator(
                  onRefresh: () async => setState(() => tasks = _load()),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    children: [
                      Text(
                        '전환 확정 후 계정별 처리 상태를 확인하고, '
                        '담당자에게 전달할 코드를 발급할 수 있어요.',
                        style: AppText.body,
                      ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text('생성된 처리 작업이 없어요.', style: AppText.body),
                        ),
                      for (final item in items)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.listDivider),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                accountNames[item.accountId] ?? '계정',
                                style: AppText.listTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.action.label} · ${item.status.label}',
                                style: AppText.listCaption,
                              ),
                              if (item.actionMessage?.isNotEmpty == true)
                                Text(item.actionMessage!, style: AppText.body),
                              if (item.failureReason?.isNotEmpty == true)
                                Text(
                                  '실패 사유: ${item.failureReason}',
                                  style: AppText.helper,
                                ),
                              if (item.canRequest)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: busyId == null
                                        ? () => _request(item)
                                        : null,
                                    child: Text(
                                      item.requestCount == 0
                                          ? '처리 코드 발급'
                                          : '처리 코드 재발급',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        '코드는 자동 발송되지 않습니다. 담당자에게 직접 전달해 주세요.',
                        style: AppText.helper,
                      ),
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

Future<void> _showCodes(
  BuildContext context,
  List<AccountHandlingRequest> requests,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.white,
  builder: (sheetContext) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('처리 요청 코드', style: AppText.screenTitle),
            const SizedBox(height: 8),
            Text(
              '각 담당자에게 해당 코드만 직접 전달해 주세요. '
              '이 창을 닫으면 다시 볼 수 없습니다.',
              style: AppText.body,
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                children: [
                  for (final request in requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.name, style: AppText.section),
                          const SizedBox(height: 6),
                          Text(
                            request.token,
                            style: AppText.body.copyWith(color: AppColors.ink),
                          ),
                          Text(
                            '만료: ${request.expiresAt.toLocal().year}년 '
                            '${request.expiresAt.toLocal().month}월 '
                            '${request.expiresAt.toLocal().day}일',
                            style: AppText.helper,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: request.token),
                              );
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('코드를 복사했어요. 직접 전달해 주세요.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_outlined, size: 17),
                            label: const Text('복사'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            PrimaryButton(
              label: '닫기',
              height: 48,
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    ),
  ),
);
