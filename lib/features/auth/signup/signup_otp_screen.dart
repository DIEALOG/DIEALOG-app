import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/otp_input.dart';
import '../../../data/providers.dart';
import 'signup_draft.dart';
import 'signup_scaffold.dart';

class SignupOtpScreen extends ConsumerStatefulWidget {
  const SignupOtpScreen({super.key});

  @override
  ConsumerState<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends ConsumerState<SignupOtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  var _remaining = const Duration(minutes: 3);
  var _busy = false;
  var _lock = false;
  String? _error;

  bool get _expired => _remaining <= Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = const Duration(minutes: 3));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = _remaining - const Duration(seconds: 1);
      setState(() => _remaining = next);
      if (next <= Duration.zero) timer.cancel();
    });
  }

  String get _clock {
    final seconds = _remaining.inSeconds.clamp(0, 24 * 3600);
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resend() async {
    final phone = ref.read(signupDraftProvider).phone;
    setState(() {
      _busy = true;
      _error = null;
      _lock = false;
    });
    try {
      await ref.read(verificationRepositoryProvider).sendCode(phone);
      if (!mounted) return;
      _code.clear();
      _startTimer();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_lock || _expired || _code.text.length != 6) return;
    final phone = ref.read(signupDraftProvider).phone;
    setState(() {
      _busy = true;
      _lock = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(verificationRepositoryProvider)
          .verifyCode(phone, _code.text);
      if (!mounted) return;
      if (ok) {
        context.push(Routes.signupTerms);
        return;
      }
      setState(() {
        _error = '인증번호가 올바르지 않아요.';
        _lock = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _lock = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(signupDraftProvider).phone;
    final complete = _code.text.length == 6 && !_expired;
    return SignupScaffold(
      step: 5,
      title: '문자로 받은\n인증번호를 입력해 주세요',
      subtitle: '$phone으로 인증번호를 보냈어요.',
      buttonLabel: '인증하고 다음',
      buttonEnabled: complete,
      busy: _busy,
      onNext: _verify,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('인증번호', style: AppText.fieldLabel),
          const SizedBox(height: 9),
          OtpInput(
            controller: _code,
            enabled: !_expired && !_busy,
            onChanged: (_) => setState(() {}),
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: 10),
          Text(
            _expired ? '인증 시간이 지났어요. 다시 받아 주세요.' : '인증번호 유효시간  $_clock',
            style: AppText.helper.copyWith(
              color: _expired ? AppColors.unread : AppColors.muted,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: AppText.helper.copyWith(color: AppColors.unread)),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: _busy ? null : _resend,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.navy,
              textStyle: AppText.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
            child: const Text('인증번호 다시 받기'),
          ),
        ],
      ),
    );
  }
}
