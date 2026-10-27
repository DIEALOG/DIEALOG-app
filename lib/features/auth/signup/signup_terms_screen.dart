import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_icon.dart';
import '../auth_controller.dart';
import 'signup_draft.dart';
import 'signup_scaffold.dart';

class SignupTermsScreen extends ConsumerStatefulWidget {
  const SignupTermsScreen({super.key});

  @override
  ConsumerState<SignupTermsScreen> createState() => _SignupTermsScreenState();
}

class _SignupTermsScreenState extends ConsumerState<SignupTermsScreen> {
  var _service = false;
  var _privacy = false;
  var _marketing = false;
  var _busy = false;
  String? _error;

  bool get _all => _service && _privacy && _marketing;

  void _setAll(bool value) {
    setState(() {
      _service = value;
      _privacy = value;
      _marketing = value;
    });
  }

  Future<void> _submit() async {
    final draft = ref.read(signupDraftProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signup(
            name: draft.name,
            email: draft.email,
            password: draft.password,
            phoneNumber: draft.phone,
          );
      if (!mounted) return;
      context.go(Routes.signupComplete);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      step: 6,
      title: '시작하기 전에\n약관을 확인해 주세요',
      subtitle: '기록을 안전하게 맡기기 위한 약속이에요.',
      buttonLabel: '동의하고 가입하기',
      buttonEnabled: _all,
      busy: _busy,
      footnote: _error ?? '필수 약관에 동의하면 가입할 수 있어요.',
      onNext: _submit,
      child: Column(
        children: [
          _AllRow(checked: _all, onTap: () => _setAll(!_all)),
          const SizedBox(height: 18),
          _TermRow(
            label: '개인정보 제3자 해외이전 사전동의 (필수)',
            checked: _service,
            onTap: () => setState(() => _service = !_service),
          ),
          _TermRow(
            label: '개인정보 처리방침 (필수)',
            checked: _privacy,
            onTap: () => setState(() => _privacy = !_privacy),
          ),
          _TermRow(
            label: '마케팅 수신 동의 (이메일, SMS, 우편 등) (필수)',
            checked: _marketing,
            onTap: () => setState(() => _marketing = !_marketing),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('각 항목을 눌러 내용을 확인할 수 있어요.', style: AppText.helper),
          ),
        ],
      ),
    );
  }
}

class _AllRow extends StatelessWidget {
  const _AllRow({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.termsFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 16),
              _Check(checked: checked),
              const SizedBox(width: 14),
              Text(
                '전체 동의',
                style: AppText.fieldValue.copyWith(
                  fontSize: 17,
                  height: 28 / 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            _Check(checked: checked, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.body.copyWith(color: AppColors.ink))),
            const AppIcon(
              'assets/icons/icon_chevron_right.svg',
              size: 16,
              color: Color(0xFFB8BEC7),
            ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.checked, this.size = 22});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (checked) {
      return AppIcon('assets/images/icon_check_on.svg', size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.fieldLine, width: 1.5),
        color: AppColors.white,
      ),
    );
  }
}
