import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/transition_confirmer.dart';
import '../../data/providers.dart';
import 'confirmer_add_screen.dart';
import 'settings_providers.dart';

/// 19-1: who vouches that a death report is true.
class ConfirmersScreen extends ConsumerWidget {
  const ConfirmersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(confirmerBoardProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('사후 전환 확인자', style: AppText.screenTitle),
            ),
            Expanded(
              child: board.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Failed(
                  message: error is ApiException
                      ? error.message
                      : '확인자를 불러오지 못했어요.',
                  onRetry: () => ref.invalidate(confirmerBoardProvider),
                ),
                data: (data) => _Body(data: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final ConfirmerBoard data;

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    TransitionConfirmer confirmer,
  ) async {
    if (!data.canRevoke(confirmer)) {
      await _showMinimumDialog(context, data.policy.minimumConfirmers);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _showRevokeDialog(context, confirmer.name);
    if (!confirmed) return;
    try {
      await ref.read(transitionRepositoryProvider).revoke(confirmer.id);
      ref.invalidate(confirmerBoardProvider);
      ref.invalidate(settingsOverviewProvider);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _resend(
    BuildContext context,
    WidgetRef ref,
    TransitionConfirmer confirmer,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(transitionRepositoryProvider).resend(confirmer.id);
      ref.invalidate(confirmerBoardProvider);
      messenger.showSnackBar(const SnackBar(content: Text('초대를 다시 보냈어요.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = data.active;
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(confirmerBoardProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Text(
            '사후 전환 요청이 들어오면 사실 여부를 확인해 줄 사람을 지정합니다.',
            style: AppText.paragraph,
          ),
          const SizedBox(height: 24),
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('아직 지정한 확인자가 없어요.', style: AppText.body),
            )
          else
            for (final confirmer in active)
              _ConfirmerRow(
                confirmer: confirmer,
                relationship: data.personFor(confirmer)?.relationship,
                onRevoke: () => _revoke(context, ref, confirmer),
                onResend: () => _resend(context, ref, confirmer),
              ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ConfirmerAddScreen(),
                  ),
                );
                ref.invalidate(confirmerBoardProvider);
                ref.invalidate(settingsOverviewProvider);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.inkDeep),
              child: Text('+ 확인자 추가', style: AppText.section),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '확인자는 전환 사실만 확인합니다. 비밀번호나 남기는 말의 열람 권한은 별도로 지정합니다.',
            style: AppText.helper,
          ),
          const SizedBox(height: 14),
          Text(
            '최소 ${data.policy.minimumConfirmers}명의 수락 완료 확인자가 필요합니다. '
            '초대 대기 중인 사람은 유효 인원에 포함되지 않습니다.',
            style: AppText.helper,
          ),
        ],
      ),
    );
  }
}

class _ConfirmerRow extends StatelessWidget {
  const _ConfirmerRow({
    required this.confirmer,
    required this.relationship,
    required this.onRevoke,
    required this.onResend,
  });

  final TransitionConfirmer confirmer;
  final String? relationship;
  final VoidCallback onRevoke;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final pending = confirmer.status == ConfirmerStatus.pending;
    final relation = relationship?.isNotEmpty == true
        ? relationship!
        : '관계 미지정';
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.listDivider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.avatarMuted,
            child: Text(
              confirmer.name.isEmpty ? '?' : confirmer.name[0],
              style: AppText.section,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(confirmer.name, style: AppText.section),
                const SizedBox(height: 3),
                Text(
                  '$relation · ${pending ? '초대 대기' : '초대 수락'}',
                  style: AppText.listCaption,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: pending ? onResend : onRevoke,
            style: TextButton.styleFrom(
              foregroundColor: pending ? AppColors.progress : AppColors.unread,
            ),
            child: Text(
              pending ? '재전송' : '해제',
              style: AppText.body.copyWith(
                color: pending ? AppColors.progress : AppColors.unread,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: AppText.body),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

/// 19-3
Future<bool> _showRevokeDialog(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('$name 님을 해제할까요?', style: AppText.stepTitle),
      content: Text(
        '사후 전환 확인자에서만 해제됩니다. 기존 관계자와 데이터 열람 권한은 유지됩니다.',
        style: AppText.paragraph,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              '확인자 해제',
              style: AppText.button.copyWith(color: AppColors.white),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: AppText.section),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 19-6
Future<void> _showMinimumDialog(BuildContext context, int minimum) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('확인자를 더 해제할 수 없어요', style: AppText.stepTitle),
        content: Text(
          '사후 전환을 위해 최소 $minimum명의 수락 완료 확인자가 필요합니다. '
          '새로운 확인자를 추가하고 초대 수락이 완료된 후 다시 시도해 주세요.',
          style: AppText.paragraph,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '확인',
                style: AppText.button.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
