import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../../data/providers.dart';
import 'legacy_providers.dart';
import 'widgets/account_sections.dart';
import 'widgets/action_method_sheet.dart';
import 'widgets/form_fields.dart';

/// `06-1 · 처리 지침 편집`
///
/// The API has no account update endpoint, so saving recreates the account and
/// pops the new id back to the detail screen.
class AccountEditScreen extends ConsumerStatefulWidget {
  const AccountEditScreen({
    super.key,
    required this.legacyId,
    required this.accountId,
  });

  final String legacyId;
  final String accountId;

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _message = TextEditingController();

  AccountActionKind? _kind;
  var _busy = false;
  String? _error;
  var _loaded = false;

  AccountKey get _key =>
      (legacyId: widget.legacyId, accountId: widget.accountId);

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _load(Account account) {
    if (_loaded) return;
    _loaded = true;
    _kind = account.action?.kind ?? AccountActionKind.delete;
    _message.text = account.action?.message ?? '';
  }

  Future<void> _pickKind() async {
    final picked = await showActionMethodSheet(
      context,
      selected: _kind ?? AccountActionKind.delete,
    );
    // Dismissing keeps the current choice, and never clears the detail text.
    if (picked != null) setState(() => _kind = picked);
  }

  Future<void> _save(Account account) async {
    final kind = _kind ?? AccountActionKind.delete;
    final message = _message.text.trim();
    if (kind == AccountActionKind.other && message.isEmpty) {
      setState(() => _error = '직접 작성은 상세 지침을 적어야 저장할 수 있어요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await ref.read(legacyRepositoryProvider).replaceAccount(
            widget.legacyId,
            account.copyWith(
              action: AccountAction(
                kind: kind,
                message: message.isEmpty ? null : message,
              ),
            ),
          );
      ref
        ..invalidate(dataOverviewProvider)
        ..invalidate(accountProvider(_key))
        ..invalidate(accountDetailProvider(_key));
      if (mounted) context.pop(saved.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider(_key));
    return Scaffold(
      body: SafeArea(
        child: account.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e is ApiException ? e.message : '데이터를 불러오지 못했어요.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (data) {
            _load(data);
            return Column(
              children: [
                ScreenHeader(
                  actionLabel: '저장',
                  onAction: _busy ? null : () => _save(data),
                ),
                Expanded(child: _form(data)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _SaveButton(
                    busy: _busy,
                    onPressed: () => _save(data),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form(Account account) {
    final kind = _kind ?? AccountActionKind.delete;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          account.type?.label ?? '기타',
          style: AppText.rowValue.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: 3),
        Text(account.name, style: AppText.screenTitle),
        const SizedBox(height: 38),
        const FieldLabel('처리 방식'),
        const SizedBox(height: 8),
        SelectField(value: kind.label, onTap: _pickKind),
        const SizedBox(height: 36),
        const FieldLabel('상세 지침', optional: true),
        const SizedBox(height: 12),
        _MessageField(controller: _message),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: AppText.helper.copyWith(color: AppColors.unread),
          ),
        ],
        const SizedBox(height: 36),
        AccountAudienceSection(account: account),
        const SizedBox(height: 32),
        AccountInfoSection(account: account),
      ],
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.inputLine),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: AppColors.navy,
        style: AppText.rowValue.copyWith(
          fontWeight: FontWeight.w400,
          height: 24.75 / 15,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '맡은 사람이 무엇을 해야 하는지 적어 주세요.',
          hintStyle: AppText.rowValue.copyWith(
            fontWeight: FontWeight.w400,
            height: 24.75 / 15,
            letterSpacing: 0,
            color: AppColors.hint,
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.inkDeep,
          disabledBackgroundColor: AppColors.inkDeep.withValues(alpha: 0.38),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                ),
              )
            : Text(
                '변경 사항 저장',
                style: AppText.listCaption.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 21 / 13,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
