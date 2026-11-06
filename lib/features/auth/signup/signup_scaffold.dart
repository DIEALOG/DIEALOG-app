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
    this.footnoteIsError = false,
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
  final bool footnoteIsError;
  final bool buttonEnabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    // Read before the Scaffold: `resizeToAvoidBottomInset` strips the keyboard
    // inset from its own body, so inside it this always reads zero.
    //
    // Every step autofocuses its field, so the keyboard is already up when the
    // screen appears. Shrinking the heading and dropping the subtitle then buys
    // back the room the fields need instead of pushing them off the bottom.
    final compact = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppBackButton(),
                  Expanded(child: _Progress(step: step)),
                  const SizedBox(width: 12),
                  Text('$step / 6', style: AppText.stepIndex),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: compact ? 12 : 24),
                        Text(
                          title,
                          style: compact
                              ? AppText.stepTitle.copyWith(
                                  fontSize: 21,
                                  height: 30 / 21,
                                )
                              : AppText.stepTitle,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 13),
                          Text(subtitle, style: AppText.body),
                        ],
                        SizedBox(height: compact ? 20 : 34),
                        child,
                        const SizedBox(height: 12),
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
                    if (!compact || footnoteIsError) ...[
                      const SizedBox(height: 8),
                      Text(
                        footnote,
                        style: footnoteIsError
                            ? AppText.helper.copyWith(color: AppColors.unread)
                            : AppText.footnote,
                        textAlign: TextAlign.center,
                      ),
                    ],
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
