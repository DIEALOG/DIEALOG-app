import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';

class StakeholderTaskResultScreen extends ConsumerStatefulWidget {
  const StakeholderTaskResultScreen({super.key});

  @override
  ConsumerState<StakeholderTaskResultScreen> createState() =>
      _StakeholderTaskResultScreenState();
}

class _StakeholderTaskResultScreenState
    extends ConsumerState<StakeholderTaskResultScreen> {
  final code = TextEditingController();
  final message = TextEditingController();
  bool? success;
  bool busy = false;
  String? error;
  String? result;

  @override
  void dispose() {
    code.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (code.text.trim().isEmpty || success == null) {
      setState(() => error = '처리 코드와 결과를 입력해 주세요.');
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('처리 결과를 제출할까요?'),
        content: const Text('제출한 결과는 나중에 바꿀 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('제출하기'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final task = await ref
          .read(stakeholderTaskRepositoryProvider)
          .submitResult(
            code.text.trim(),
            success: success!,
            message: message.text.trim().isEmpty ? null : message.text.trim(),
          );
      if (mounted) setState(() => result = task.status.label);
      code.clear();
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is ApiException
              ? failure.message
              : '처리 결과를 제출하지 못했어요.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('계정 처리 결과'), centerTitle: true),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: ListView(
          children: [
            Text(
              result == null ? '맡은 계정 처리' : '결과를 제출했어요',
              style: AppText.screenTitle,
            ),
            const SizedBox(height: 12),
            Text(
              result == null
                  ? '처리 대상과 지침을 코드 전달자에게 확인한 뒤 '
                        '완료 또는 실패를 보고해 주세요.'
                  : '현재 작업 상태: $result',
              style: AppText.body,
            ),
            if (result == null) ...[
              const SizedBox(height: 28),
              Text('처리 코드', style: AppText.fieldLabel),
              const SizedBox(height: 8),
              TextField(
                controller: code,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  hintText: '전달받은 코드를 붙여넣으세요',
                  filled: true,
                  fillColor: AppColors.field,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text('처리 결과', style: AppText.fieldLabel),
              RadioGroup<bool>(
                groupValue: success,
                onChanged: busy
                    ? (_) {}
                    : (value) => setState(() => success = value),
                child: const Column(
                  children: [
                    RadioListTile<bool>(title: Text('완료했어요'), value: true),
                    RadioListTile<bool>(title: Text('처리하지 못했어요'), value: false),
                  ],
                ),
              ),
              TextField(
                controller: message,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '남길 내용이 있다면 입력해 주세요',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.unread)),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: '결과 제출',
                busy: busy,
                onPressed: busy ? null : _submit,
              ),
            ] else ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: '닫기',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
