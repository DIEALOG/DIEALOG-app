import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아직 준비 중인 기능이에요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 37),
                  child: ListView(
                    children: [
                      Text('로그인', style: AppText.authTitle),
                      const SizedBox(height: 40),
                      AppTextField(
                        label: '이메일',
                        controller: _email,
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: '비밀번호',
                        controller: _password,
                        hint: '비밀번호',
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: AppText.helper.copyWith(color: AppColors.unread),
                        ),
                      ],
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: '로그인',
                        onPressed: _submit,
                        busy: _submitting,
                        enabled: _email.text.isNotEmpty && _password.text.isNotEmpty,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _soon,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.muted,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text('비밀번호 찾기', style: AppText.link),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _soon,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.muted,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text('휴대폰 번호로 로그인', style: AppText.link),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
