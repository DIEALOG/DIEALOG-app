import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import 'signup_draft.dart';
import 'signup_rules.dart';
import 'signup_scaffold.dart';

class SignupEmailScreen extends ConsumerStatefulWidget {
  const SignupEmailScreen({super.key});

  @override
  ConsumerState<SignupEmailScreen> createState() => _SignupEmailScreenState();
}

class _SignupEmailScreenState extends ConsumerState<SignupEmailScreen> {
  late final _email =
      TextEditingController(text: ref.read(signupDraftProvider).email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = SignupRules.emailOk(_email.text);
    return SignupScaffold(
      step: 2,
      title: '로그인에 사용할\n이메일을 알려주세요',
      subtitle: '중요한 안내도 이 이메일로 보내드려요.',
      buttonLabel: '다음',
      buttonEnabled: ok,
      onNext: () {
        ref.read(signupDraftProvider.notifier).setEmail(_email.text);
        context.push(Routes.signupPassword);
      },
      child: AppTextField(
        label: '이메일',
        controller: _email,
        hint: 'name@example.com',
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        helper: Text('자주 사용하는 이메일 주소를 입력해 주세요.', style: AppText.helper),
      ),
    );
  }
}
