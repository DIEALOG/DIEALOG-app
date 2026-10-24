import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/providers.dart';
import 'signup_draft.dart';
import 'signup_rules.dart';
import 'signup_scaffold.dart';

class SignupPhoneScreen extends ConsumerStatefulWidget {
  const SignupPhoneScreen({super.key});

  @override
  ConsumerState<SignupPhoneScreen> createState() => _SignupPhoneScreenState();
}

class _SignupPhoneScreenState extends ConsumerState<SignupPhoneScreen> {
  late final _phone =
      TextEditingController(text: ref.read(signupDraftProvider).phone);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final formatted = SignupRules.formatPhone(_phone.text);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(verificationRepositoryProvider).sendCode(formatted);
      if (!mounted) return;
      ref.read(signupDraftProvider.notifier).setPhone(formatted);
      context.push(Routes.signupOtp);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = SignupRules.phoneOk(_phone.text);
    return SignupScaffold(
      step: 4,
      title: '휴대폰 번호를\n알려주세요',
      subtitle: '본인 확인을 위해 인증번호를 보내드려요.',
      buttonLabel: '인증번호 받기',
      buttonEnabled: ok,
      busy: _busy,
      onNext: _send,
      child: AppTextField(
        label: '휴대폰 번호',
        controller: _phone,
        hint: '010-0000-0000',
        autofocus: true,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        textInputAction: TextInputAction.done,
        onChanged: (value) {
          final formatted = SignupRules.formatPhone(value);
          if (formatted != value) {
            _phone.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
          setState(() {});
        },
        helper: Text(
          _error ?? '입력한 번호로 인증번호가 발송돼요.',
          style: _error == null
              ? AppText.helper
              : AppText.helper.copyWith(color: const Color(0xFFD9483B)),
        ),
      ),
    );
  }
}
