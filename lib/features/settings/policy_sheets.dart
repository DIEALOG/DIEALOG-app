import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

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

Future<void> showTransitionCriteriaSheet(
  BuildContext context,
  TransitionPolicy policy,
) => _showSheet<void>(context, (context) => _CriteriaSheet(policy: policy));

class _CriteriaSheet extends ConsumerStatefulWidget {
  const _CriteriaSheet({required this.policy});

  final TransitionPolicy policy;

  @override
  ConsumerState<_CriteriaSheet> createState() => _CriteriaSheetState();
}

class _CriteriaSheetState extends ConsumerState<_CriteriaSheet> {
  late final _days = TextEditingController(
    text: '${widget.policy.waitingPeriodDays}',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final days = int.tryParse(_days.text);
    if (days == null || days < 0) {
      setState(() => _error = '대기 기간을 0일 이상의 숫자로 입력해 주세요.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(transitionRepositoryProvider)
          .updatePolicy(waitingPeriodDays: days);
      ref.invalidate(settingsOverviewProvider);
      ref.invalidate(confirmerBoardProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: _Grabber()),
            const SizedBox(height: 12),
            const _SheetHeader('사후 전환 기준'),
            const SizedBox(height: 16),
            Text(
              '확인자 ${widget.policy.minimumConfirmers}명 이상 동의',
              style: AppText.section,
            ),
            const SizedBox(height: 24),
            Text('대기 기간(일)', style: AppText.fieldLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '0'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppText.helper.copyWith(color: AppColors.unread),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: '저장', busy: _saving, onPressed: _save),
          ],
        ),
      ),
    ),
  );
}

/// 19-13~16: pick how often the server checks in.
Future<void> showAliveCheckIntervalSheet(
  BuildContext context,
  TransitionPolicy policy,
) => _showSheet<void>(context, (context) => _IntervalSheet(policy: policy));

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
      messenger.showSnackBar(SnackBar(content: Text(e.userMessage)));
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(label: '저장', busy: _saving, onPressed: _save),
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
