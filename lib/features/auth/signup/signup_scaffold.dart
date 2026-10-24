import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/primary_button.dart';

class SignupScaffold extends StatelessWidget {
  const SignupScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onNext,
    required this.child,
    this.footnote = '입력한 내용은 이전 단계에서 수정할 수 있어요.',
    this.buttonEnabled = false,
    this.busy = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onNext;
  final Widget child;
  final String footnote;
  final bool buttonEnabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('$step / 6', style: AppText.stepIndex),
                        ),
                        const SizedBox(height: 8),
                        _Progress(step: step),
                        const SizedBox(height: 21),
                        Text(title, style: AppText.stepTitle),
                        const SizedBox(height: 13),
                        Text(subtitle, style: AppText.body),
                        const SizedBox(height: 34),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: buttonLabel,
                      onPressed: onNext,
                      enabled: buttonEnabled,
                      busy: busy,
                    ),
                    const SizedBox(height: 8),
                    Text(footnote, style: AppText.footnote, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 6; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.navy : AppColors.track,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
