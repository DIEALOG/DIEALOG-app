import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import 'signup_draft.dart';
import 'signup_rules.dart';
import 'signup_scaffold.dart';

class SignupNameScreen extends ConsumerStatefulWidget {
  const SignupNameScreen({super.key});

  @override
  ConsumerState<SignupNameScreen> createState() => _SignupNameScreenState();
}

class _SignupNameScreenState extends ConsumerState<SignupNameScreen> {
  late final _name = TextEditingController(text: ref.read(signupDraftProvider).name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = SignupRules.nameOk(_name.text);
    return SignupScaffold(
      step: 1,
      title: '어떻게 불러드릴까요?',
      subtitle: 'DIEALOG에서 사용할 이름을 알려주세요.',
      buttonLabel: '다음',
      buttonEnabled: ok,
      onNext: () {
        ref.read(signupDraftProvider.notifier).setName(_name.text);
        context.push(Routes.signupEmail);
      },
      child: AppTextField(
        label: '이름',
        controller: _name,
        hint: '이름',
        autofocus: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (ok) {
            ref.read(signupDraftProvider.notifier).setName(_name.text);
            context.push(Routes.signupEmail);
          }
        },
        helper: Text('나를 알아볼 수 있는 이름을 입력해 주세요.', style: AppText.helper),
      ),
    );
  }
}
