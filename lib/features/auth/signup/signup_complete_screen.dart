import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/primary_button.dart';
import 'signup_draft.dart';

class SignupCompleteScreen extends ConsumerWidget {
  const SignupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(signupDraftProvider).name;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/diealog_logo.png', width: 93, height: 56),
              const SizedBox(height: 39),
              Text('$name님,\n만나서 반가워요', style: AppText.stepTitle.copyWith(fontSize: 28, height: 41 / 28)),
              const SizedBox(height: 24),
              Text(
                '가입이 완료됐어요.\n이제 나만의 기록을 남겨보세요.',
                style: AppText.body.copyWith(fontSize: 16, height: 28 / 16),
              ),
              const Spacer(),
              PrimaryButton(
                label: '내 기록 시작하기',
                onPressed: () {
                  ref.read(signupDraftProvider.notifier).clear();
                  context.go(Routes.home);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
