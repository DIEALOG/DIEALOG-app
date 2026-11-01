import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/transition_policy.dart';
import '../../data/providers.dart';
import 'settings_providers.dart';

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: builder,
    );

class _SheetHeader extends StatelessWidget {
  const _SheetHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: AppText.stepTitle),
      const Spacer(),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(foregroundColor: AppColors.muted),
        child: Text('닫기', style: AppText.body),
      ),
    ],
  );
}

/// 19-12: read-only explanation of the current policy.
Future<void> showTransitionCriteriaSheet(
  BuildContext context,
  TransitionPolicy policy,
) => _showSheet<void>(
  context,
  (context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: _Grabber()),
        const SizedBox(height: 12),
        const _SheetHeader('사후 전환 기준'),
        const SizedBox(height: 16),
        Text('확인자 ${policy.minimumConfirmers}명 이상 동의', style: AppText.section),
        const SizedBox(height: 8),
        Text(
          '사후 전환 요청에 대해 지정된 확인자 중 ${policy.minimumConfirmers}명 이상이 '
          '사실이라고 확인해야 합니다.',
          style: AppText.paragraph,
        ),
        const Divider(height: 32, color: AppColors.listDivider),
        Text('${policy.waitingPeriodDays}일 대기', style: AppText.section),
        const SizedBox(height: 8),
        Text('확인 기준이 충족된 이후 추가 검토 및 대기 기간을 거칩니다.', style: AppText.paragraph),
        const SizedBox(height: 20),
        Text(
          '확인자의 동의만으로 기록이 즉시 공개되지는 않습니다. 추가 확인이 완료되어야 사후 공개가 진행됩니다.',
          style: AppText.helper,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: '확인',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  ),
);

/// 19-13~16: pick how often the server checks in.
Future<void> showAliveCheckIntervalSheet(
  BuildContext context,
  TransitionPolicy policy,
) => _showSheet<void>(
  context,
  (context) => _IntervalSheet(policy: policy),
);

class _IntervalSheet extends ConsumerStatefulWidget {
  const _IntervalSheet({required this.policy});

  final TransitionPolicy policy;

  @override
  ConsumerState<_IntervalSheet> createState() => _IntervalSheetState();
}

class _IntervalSheetState extends ConsumerState<_IntervalSheet> {
  late int _days = widget.policy.aliveCheckIntervalDays;
  var _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(transitionRepositoryProvider)
          .updatePolicy(aliveCheckIntervalDays: _days);
      ref.invalidate(settingsOverviewProvider);
      ref.invalidate(confirmerBoardProvider);
      navigator.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: _Grabber()),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _SheetHeader('생존 확인 주기'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Text(
              '설정한 주기마다 생존 여부를 확인할 수 있도록 알림을 보내드립니다.',
              style: AppText.paragraph,
            ),
          ),
          for (final days in TransitionPolicy.intervalChoices)
            _IntervalRow(
              days: days,
              selected: days == _days,
              onTap: () => setState(() => _days = days),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Text(
              '생존 확인 요청에 응답하지 않았다는 이유만으로 사후 공개가 자동으로 확정되지는 않습니다.',
              style: AppText.helper,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(
              label: '저장',
              busy: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: selected ? AppColors.optionSelected : null,
      child: Row(
        children: [
          Text(
            days == TransitionPolicy.defaultInterval
                ? '$days일마다 (기본)'
                : '$days일마다',
            style: AppText.body.copyWith(color: AppColors.ink),
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check, size: 20, color: AppColors.inkDeep),
        ],
      ),
    ),
  );
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.track,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
