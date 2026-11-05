import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';

/// The four things a brand-new account has to do before anything would
/// actually reach anyone after death.
enum HomeGuideKind { data, people, confirmer, letter }

class HomeGuideStep {
  const HomeGuideStep({
    required this.kind,
    required this.title,
    required this.caption,
    required this.done,
  });

  final HomeGuideKind kind;
  final String title;
  final String caption;
  final bool done;
}

/// Progress through the first-run guide, read straight off the home snapshot
/// so a step ticks itself off the moment the user finishes it.
class HomeGuide {
  const HomeGuide(this.steps);

  factory HomeGuide.of({
    required int accounts,
    required int people,
    required int confirmers,
    required int letters,
  }) => HomeGuide([
    HomeGuideStep(
      kind: HomeGuideKind.data,
      title: '남길 데이터 등록하기',
      caption: '계정 하나를 등록해 보세요',
      done: accounts > 0,
    ),
    HomeGuideStep(
      kind: HomeGuideKind.people,
      title: '관계자 추가하기',
      caption: '기록을 전달할 사람을 등록해요',
      done: people > 0,
    ),
    HomeGuideStep(
      kind: HomeGuideKind.confirmer,
      title: '확인자 지정하기',
      caption: '사후 공개를 확인해 줄 사람이 필요해요',
      done: confirmers > 0,
    ),
    HomeGuideStep(
      kind: HomeGuideKind.letter,
      title: '남기는 말 쓰기',
      caption: '전하고 싶은 말을 미리 적어 둬요',
      done: letters > 0,
    ),
  ]);

  final List<HomeGuideStep> steps;

  int get doneCount => steps.where((step) => step.done).length;

  /// Nothing left to guide, so the card retires without being dismissed.
  bool get finished => doneCount == steps.length;

  /// The step the card points at; the rest stay collapsed to one line.
  HomeGuideStep? get next => steps.where((step) => !step.done).firstOrNull;
}

class HomeGuideCard extends StatelessWidget {
  const HomeGuideCard({
    super.key,
    required this.guide,
    required this.onOpen,
    required this.onDismiss,
  });

  final HomeGuide guide;
  final ValueChanged<HomeGuideKind> onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final next = guide.next;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('시작 안내', style: AppText.section),
              const Spacer(),
              Text(
                '${guide.doneCount} / ${guide.steps.length}',
                style: AppText.listCaption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(
            value: guide.doneCount / guide.steps.length,
            track: AppColors.track,
            fill: AppColors.progress,
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? '준비가 모두 끝났어요.'
                : '아래 순서를 따라가면 사후 전달 준비가 끝나요.',
            style: AppText.helper,
          ),
          const SizedBox(height: 6),
          for (final step in guide.steps)
            _StepRow(step: step, onTap: () => onOpen(step.kind)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                '안내 숨기기',
                style: AppText.listCaption.copyWith(color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.onTap});

  final HomeGuideStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            step.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: step.done ? AppColors.progress : AppColors.chevron,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: step.done
                      ? AppText.listTitle.copyWith(color: AppColors.muted)
                      : AppText.listTitle,
                ),
                if (!step.done) ...[
                  const SizedBox(height: 3),
                  Text(step.caption, style: AppText.helper.copyWith(height: 1)),
                ],
              ],
            ),
          ),
          if (!step.done)
            const AppIcon(
              'assets/icons/icon_chevron_right.svg',
              size: 16,
              color: AppColors.chevron,
            ),
        ],
      ),
    ),
  );
}

/// One continuous bar, filled by ratio. Replaces the five fixed segments that
/// could not tell `3 / 4` from `4 / 5`.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.track,
    required this.fill,
    this.height = 6,
  });

  final double value;
  final Color track;
  final Color fill;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final radius = BorderRadius.circular(height / 2);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(color: track, borderRadius: radius),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: height,
            width: constraints.maxWidth * ratio,
            decoration: BoxDecoration(color: fill, borderRadius: radius),
          ),
        ],
      ),
    );
  }
}
