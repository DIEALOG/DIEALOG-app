import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/confirmer_access.dart';
import '../../data/providers.dart';
import 'confirmer_cases_screen.dart';

class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  late final _code = TextEditingController(text: widget.initialToken ?? '');
  bool _busy = false;
  String? _error;
  String? _result;
  String? _recoveryToken;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _respond({required bool accept}) async {
    final token = _code.text.trim();
    if (token.isEmpty) {
      setState(() => _error = '초대 코드를 입력해 주세요.');
      return;
    }
    if (!accept) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('초대를 거절할까요?'),
          content: const Text('거절한 초대 코드는 다시 사용할 수 없어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('거절'),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(confirmerRepositoryProvider);
      if (accept) {
        final access = await repository.acceptInvitation(token);
        try {
          await ref
              .read(confirmerSessionStoreProvider)
              .upsert(ConfirmerSession.fromAccess(access));
          if (mounted) setState(() => _result = '확인자 초대를 수락했어요.');
        } catch (_) {
          if (mounted) {
            setState(() {
              _result = '초대는 수락됐지만 인증 정보를 저장하지 못했어요.';
              _recoveryToken = access.authToken;
            });
          }
        }
      } else {
        await repository.declineInvitation(token);
        if (mounted) setState(() => _result = '확인자 초대를 거절했어요.');
      }
      _code.clear();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } catch (_) {
      if (mounted) setState(() => _error = '초대를 처리하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('확인자 초대'), centerTitle: true),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_result ?? '초대 코드를 입력해 주세요', style: AppText.screenTitle),
            const SizedBox(height: 12),
            Text(
              '초대를 수락하면 사후 전환 요청이 들어왔을 때 '
              '사실 여부를 확인하는 역할을 맡게 됩니다. '
              '수락만으로 기록 열람 권한이 생기지는 않아요.',
              style: AppText.paragraph,
            ),
            if (_result == null) ...[
              const SizedBox(height: 32),
              Text('초대 코드', style: AppText.fieldLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _code,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: '전달받은 코드를 붙여넣으세요',
                  filled: true,
                  fillColor: AppColors.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.unread)),
              ],
              const Spacer(),
              PrimaryButton(
                label: '초대 수락',
                busy: _busy,
                onPressed: _busy ? null : () => _respond(accept: true),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy ? null : () => _respond(accept: false),
                  child: Text('거절', style: AppText.textButton),
                ),
              ),
            ] else ...[
              if (_recoveryToken != null) ...[
                const SizedBox(height: 18),
                Text(
                  '아래 인증 토큰을 안전한 곳에 보관해 주세요. '
                  '이 화면을 닫으면 다시 볼 수 없어요.',
                  style: AppText.helper,
                ),
                const SizedBox(height: 10),
                SelectableText(_recoveryToken!, style: AppText.body),
              ],
              const Spacer(),
              if (_recoveryToken == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PrimaryButton(
                    label: '내게 온 요청 보기',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ConfirmerCasesScreen(),
                      ),
                    ),
                  ),
                ),
              PrimaryButton(
                label: '닫기',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
