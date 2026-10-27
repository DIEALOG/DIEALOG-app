import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../data/models/account.dart';
import '../../../data/providers.dart';
import '../legacy_providers.dart';
import '../widgets/action_method_sheet.dart';
import '../widgets/service_sheet.dart';
import 'register_steps.dart';

/// `10 ~ 13 · 데이터 등록`: 기본 정보 → 처리 지침 → 공개 대상 → 확인.
class AccountRegisterScreen extends ConsumerStatefulWidget {
  const AccountRegisterScreen({super.key});

  @override
  ConsumerState<AccountRegisterScreen> createState() =>
      _AccountRegisterScreenState();
}

class _AccountRegisterScreenState extends ConsumerState<AccountRegisterScreen> {
  static const _steps = 4;

  final _customService = TextEditingController();
  final _name = TextEditingController();
  final _accountId = TextEditingController();
  final _password = TextEditingController();
  final _dataLocation = TextEditingController();
  final _actionMessage = TextEditingController();

  final _people = <String>{};
  final _groups = <String>{};

  ServiceChoice? _choice;
  AccountActionKind? _action;
  var _step = 0;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _customService,
      _name,
      _accountId,
      _password,
      _dataLocation,
      _actionMessage,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
        0 => _choice != null &&
            (!_choice!.custom || _customService.text.trim().isNotEmpty) &&
            _name.text.trim().isNotEmpty,
        1 => _action != null &&
            (_action != AccountActionKind.other ||
                _actionMessage.text.trim().isNotEmpty),
        _ => true,
      };

  Account get _account {
    final choice = _choice!;
    final custom = _customService.text.trim();
    final message = _actionMessage.text.trim();
    return Account(
      name: _name.text.trim(),
      type: AccountType(
        service: choice.service,
        name: choice.custom ? custom : choice.name,
      ),
      action: AccountAction(
        kind: _action ?? AccountActionKind.delete,
        message: message.isEmpty ? null : message,
      ),
      accountId: _trimmedOrNull(_accountId),
      accountPassword: _trimmedOrNull(_password),
      dataLocation: _trimmedOrNull(_dataLocation),
      stakeholderIds: _people.toList(),
      stakeholderGroupIds: _groups.toList(),
    );
  }

  static String? _trimmedOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String get _serviceLabel =>
      _choice!.custom ? _customService.text.trim() : _choice!.label;

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _pickService() async {
    final picked = await showServiceSheet(context, selected: _choice);
    if (picked != null) setState(() => _choice = picked);
  }

  Future<void> _pickAction() async {
    final picked = await showActionMethodSheet(context, selected: _action);
    if (picked != null) setState(() => _action = picked);
  }

  Future<void> _submit() async {
    if (_step < _steps - 1) {
      FocusScope.of(context).unfocus();
      setState(() => _step++);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final overview = await ref.read(dataOverviewProvider.future);
      final legacies = ref.read(legacyRepositoryProvider);
      // Accounts live under a legacy; the app keeps a single default one.
      final legacyId = overview.legacies.isNotEmpty
          ? overview.legacies.first.id
          : (await legacies.create('내 데이터')).id;
      await legacies.addAccount(legacyId, _account);
      ref.invalidate(dataOverviewProvider);
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(step: _step, steps: _steps, onBack: _back),
              Expanded(child: _body()),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    _error!,
                    style: AppText.helper.copyWith(color: AppColors.unread),
                  ),
                ),
              if (_step == 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '선택됨 '),
                        TextSpan(
                          text: '${_audienceCount()}명',
                          style: AppText.rowLabel.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    style: AppText.rowLabel,
                  ),
                ),
              _BottomBar(
                showBack: _step > 0,
                label: _step == _steps - 1 ? '저장' : '다음',
                enabled: _canContinue,
                busy: _busy,
                onBack: () => setState(() => _step--),
                onNext: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _audienceCount() {
    final overview = ref.read(dataOverviewProvider).value;
    final ids = <String>{..._people};
    for (final id in _groups) {
      final group = overview?.groups[id];
      if (group != null) ids.addAll(group.stakeholderIds);
    }
    return ids.length;
  }

  Widget _body() => switch (_step) {
        0 => BasicsStep(
            choice: _choice,
            customService: _customService,
            name: _name,
            accountId: _accountId,
            password: _password,
            dataLocation: _dataLocation,
            onPickService: _pickService,
            onChanged: () => setState(() {}),
          ),
        1 => ActionStep(
            kind: _action,
            message: _actionMessage,
            onPickKind: _pickAction,
          ),
        2 => AudienceStep(
            people: _people,
            groups: _groups,
            onTogglePerson: (id) => setState(() {
              if (!_people.remove(id)) _people.add(id);
            }),
            onToggleGroup: (id) => setState(() {
              if (!_groups.remove(id)) _groups.add(id);
            }),
          ),
        _ => ConfirmStep(
            account: _account,
            serviceLabel: _serviceLabel,
            people: _people,
            groups: _groups,
          ),
      };
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.steps,
    required this.onBack,
  });

  final int step;
  final int steps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 6),
              AppBackButton(onPressed: onBack),
              const Spacer(),
              Text(
                '${step + 1} / $steps',
                style: AppText.rowLabel.copyWith(letterSpacing: -0.16),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(height: 2, color: AppColors.divider),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: constraints.maxWidth * (step + 1) / steps,
                  decoration: BoxDecoration(
                    color: AppColors.progress,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.showBack,
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onBack,
    required this.onNext,
  });

  final bool showBack;
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          if (showBack) ...[
            SizedBox(
              width: 88,
              height: 48,
              child: OutlinedButton(
                onPressed: busy ? null : onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  foregroundColor: AppColors.ink,
                  shape: shape,
                  padding: EdgeInsets.zero,
                ),
                child: Text('이전', style: AppText.headerAction.copyWith(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: enabled && !busy ? onNext : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.38),
                  foregroundColor: AppColors.white,
                  disabledForegroundColor: AppColors.white,
                  shape: shape,
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
                        label,
                        style: AppText.headerAction.copyWith(
                          fontSize: 14,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
