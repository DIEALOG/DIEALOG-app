import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import '../shared/audience_picker.dart';
import '../shared/audience_select_screen.dart';
import '../stakeholder/people_providers.dart';
import 'legacy_providers.dart';
import 'widgets/account_sections.dart';
import 'widgets/action_method_sheet.dart';
import 'widgets/form_fields.dart';
import 'widgets/service_sheet.dart';

/// What [AccountEditScreen] hands back, so the detail screen behind it knows
/// whether to reload the account or close with it.
class AccountEdited {
  const AccountEdited.saved(String this.accountId) : deleted = false;
  const AccountEdited.deleted() : accountId = null, deleted = true;

  final String? accountId;
  final bool deleted;
}

/// `06-1 · 계정 편집`
///
/// Edits everything about an account — service, name, credentials, handling
/// instructions and audience — and can delete it.
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
  final _customService = TextEditingController();
  final _name = TextEditingController();
  final _accountId = TextEditingController();
  final _password = TextEditingController();
  final _dataLocation = TextEditingController();
  final _message = TextEditingController();

  ServiceChoice? _choice;
  AccountActionKind? _kind;
  AudienceSelection? _selection;
  var _busy = false;
  String? _error;
  var _loaded = false;

  AccountKey get _key =>
      (legacyId: widget.legacyId, accountId: widget.accountId);

  @override
  void dispose() {
    for (final controller in [
      _customService,
      _name,
      _accountId,
      _password,
      _dataLocation,
      _message,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _load(Account account) {
    if (_loaded) return;
    _loaded = true;
    final type = account.type;
    _choice =
        serviceChoices
            .where((choice) => choice.matches(type?.service, type?.name))
            .firstOrNull ??
        serviceChoices.last;
    if (_choice!.custom) _customService.text = type?.name ?? '';
    _name.text = account.name;
    _accountId.text = account.accountId ?? '';
    _dataLocation.text = account.dataLocation ?? '';
    _kind = account.action?.kind ?? AccountActionKind.delete;
    _message.text = account.action?.message ?? '';
    _selection = AudienceSelection(
      people: {
        ...account.stakeholderIds,
        for (final person in account.stakeholders) person.id,
      },
      groups: {
        ...account.stakeholderGroupIds,
        for (final group in account.stakeholderGroups) group.id,
      },
    );
  }

  Future<void> _pickService() async {
    final picked = await showServiceSheet(context, selected: _choice);
    if (picked != null) setState(() => _choice = picked);
  }

  Future<void> _pickAudience() async {
    try {
      final overview = await ref.read(dataOverviewProvider.future);
      if (!mounted) return;
      final selected = await Navigator.of(context).push<AudienceSelection>(
        MaterialPageRoute(
          builder: (_) => AudienceSelectScreen(
            people: overview.people.values.toList(),
            groups: overview.groups.values.toList(),
            initial: _selection!,
            allowEmpty: true,
            buttonLabel: '선택 완료',
          ),
        ),
      );
      if (selected != null && mounted) setState(() => _selection = selected);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    }
  }

  Future<void> _pickKind() async {
    final picked = await showActionMethodSheet(
      context,
      selected: _kind ?? AccountActionKind.delete,
    );
    // Dismissing keeps the current choice, and never clears the detail text.
    if (picked != null) setState(() => _kind = picked);
  }

  void _refresh() {
    ref
      ..invalidate(dataOverviewProvider)
      ..invalidate(homeSnapshotProvider)
      ..invalidate(peopleOverviewProvider)
      ..invalidate(accountProvider(_key))
      ..invalidate(accountDetailProvider(_key));
  }

  static String? _trimmedOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save(Account account) async {
    final choice = _choice!;
    final custom = _customService.text.trim();
    final name = _name.text.trim();
    final kind = _kind ?? AccountActionKind.delete;
    final message = _message.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '계정·데이터 이름을 입력해 주세요.');
      return;
    }
    if (choice.custom && custom.isEmpty) {
      setState(() => _error = '서비스 이름을 적어 주세요.');
      return;
    }
    if (kind == AccountActionKind.other && message.isEmpty) {
      setState(() => _error = '직접 작성은 상세 지침을 적어야 저장할 수 있어요.');
      return;
    }
    final typed = _password.text;
    // The server files a password under the account name, so a rename has to
    // carry the old one along or the credential is left behind under the old
    // name. An untouched field on an unchanged name sends nothing, which
    // leaves the stored password alone.
    final password = typed.isNotEmpty
        ? typed
        : name != account.name
        ? account.accountPassword
        : null;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(legacyRepositoryProvider)
          .updateAccount(
            widget.legacyId,
            Account(
              id: account.id,
              legacyId: account.legacyId,
              name: name,
              type: AccountType(
                service: choice.service,
                name: choice.custom ? custom : choice.name,
              ),
              action: AccountAction(
                kind: kind,
                message: message.isEmpty ? null : message,
              ),
              accountId: _trimmedOrNull(_accountId),
              accountPassword: password,
              dataLocation: _trimmedOrNull(_dataLocation),
              stakeholderIds: _selection!.people.toList(),
              stakeholderGroupIds: _selection!.groups.toList(),
            ),
          );
      _refresh();
      if (mounted) context.pop(AccountEdited.saved(saved.id));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Account account) async {
    final audience = account.disclosedTo.length;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이 계정을 삭제할까요?'),
        content: Text(
          audience == 0
              ? '저장한 계정 정보와 처리 지침이 사라져요. 되돌릴 수 없어요.'
              : '저장한 계정 정보와 처리 지침이 사라지고, '
                    '공개 대상 $audience명에게 더 이상 전달되지 않아요. 되돌릴 수 없어요.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.unread),
            ),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(legacyRepositoryProvider)
          .removeAccount(widget.legacyId, account.id);
      _refresh();
      if (mounted) context.pop(const AccountEdited.deleted());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
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
                e is ApiException ? e.userMessage : '데이터를 불러오지 못했어요.',
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
                  trailing: Row(
                    children: [
                      IconButton(
                        tooltip: '계정 삭제',
                        onPressed: _busy ? null : () => _delete(data),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 22,
                          color: AppColors.muted,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _save(data),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: AppText.headerAction.color,
                        ),
                        child: Text('저장', style: AppText.headerAction),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _form(data)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _SaveButton(busy: _busy, onPressed: () => _save(data)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form(Account account) {
    final choice = _choice!;
    final kind = _kind ?? AccountActionKind.delete;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text('계정 편집', style: AppText.screenTitle),
        const SizedBox(height: 28),
        SelectField(
          label: '서비스',
          value: choice.label,
          onTap: _busy ? () {} : _pickService,
        ),
        if (choice.custom) ...[
          const SizedBox(height: 12),
          AppFormField(
            controller: _customService,
            hint: '서비스 이름을 적어 주세요',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 20),
        AppFormField(
          label: '계정·데이터 이름',
          controller: _name,
          hint: '예: 개인 계정, 가족사진',
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        AppFormField(
          label: '아이디·이메일',
          optional: true,
          controller: _accountId,
          hint: '로그인 아이디',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        AppFormField(
          label: '비밀번호',
          optional: true,
          controller: _password,
          hint: _passwordHint(account),
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 8),
        Text(
          account.accountPassword == null
              ? '저장된 비밀번호가 없어요.'
              : '비워 두면 저장된 비밀번호를 그대로 둬요.',
          style: AppText.helper,
        ),
        const SizedBox(height: 20),
        AppFormField(
          label: '자료 위치',
          optional: true,
          controller: _dataLocation,
          hint: '폴더 경로나 링크',
        ),
        const SizedBox(height: 36),
        const FieldLabel('처리 방식'),
        const SizedBox(height: 8),
        SelectField(value: kind.label, onTap: _busy ? () {} : _pickKind),
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
        InkWell(
          onTap: _busy ? null : _pickAudience,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text('공개 대상', style: AppText.listTitle),
                const Spacer(),
                Text('변경', style: AppText.headerAction),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
        AccountAudienceSection(account: account, selection: _selection),
        const SizedBox(height: 28),
        Center(
          child: TextButton(
            onPressed: _busy ? null : () => _delete(account),
            child: const Text(
              '이 계정 삭제',
              style: TextStyle(color: AppColors.unread),
            ),
          ),
        ),
      ],
    );
  }

  static String _passwordHint(Account account) =>
      account.accountPassword == null ? '필요한 경우에만' : '변경할 때만 입력';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
