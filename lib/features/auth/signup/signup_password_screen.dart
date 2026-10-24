import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import 'signup_draft.dart';
import 'signup_rules.dart';
import 'signup_scaffold.dart';

class SignupPasswordScreen extends ConsumerStatefulWidget {
  const SignupPasswordScreen({super.key});

  @override
  ConsumerState<SignupPasswordScreen> createState() =>
      _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends ConsumerState<SignupPasswordScreen> {
  late final _password =
      TextEditingController(text: ref.read(signupDraftProvider).password);
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final password = _password.text;
    final confirm = _confirm.text;
    final longEnough = SignupRules.passwordLongEnough(password);
    final mixed = SignupRules.passwordHasLetterAndDigit(password);
    final match = SignupRules.passwordsMatch(password, confirm);
    return SignupScaffold(
      step: 3,
      title: '안전하게 사용할\n비밀번호를 만들어주세요',
      subtitle: '소중한 기록을 안전하게 보호할게요.',
      buttonLabel: '다음',
      buttonEnabled: SignupRules.passwordOk(password) && match,
      onNext: () {
        ref.read(signupDraftProvider.notifier).setPassword(password);
        context.push(Routes.signupPhone);
      },
      child: Column(
        children: [
          AppTextField(
            label: '비밀번호',
            controller: _password,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            helper: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '✓  8자 이상',
                    style: AppText.helper.copyWith(
                      color: longEnough ? AppColors.navy : AppColors.caption,
                    ),
                  ),
                  TextSpan(
                    text: '     ✓  영문·숫자 포함',
                    style: AppText.helper.copyWith(
                      color: mixed ? AppColors.navy : AppColors.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: '비밀번호 확인',
            controller: _confirm,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            helper: Text(
              '✓  비밀번호가 일치해요',
              style: AppText.helper.copyWith(
                color: match ? AppColors.navy : AppColors.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
