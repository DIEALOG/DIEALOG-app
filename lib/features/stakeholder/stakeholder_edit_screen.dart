import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/stakeholder.dart';
import '../../data/models/transition_confirmer.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import '../legacy/legacy_providers.dart';
import 'people_providers.dart';

class StakeholderEditScreen extends ConsumerStatefulWidget {
  const StakeholderEditScreen({super.key, this.person, this.overview});

  final Stakeholder? person;
  final PeopleOverview? overview;

  @override
  ConsumerState<StakeholderEditScreen> createState() =>
      _StakeholderEditScreenState();
}

class _StakeholderEditScreenState extends ConsumerState<StakeholderEditScreen> {
  late final _name = TextEditingController(text: widget.person?.name ?? '');
  late final _relationship = TextEditingController(
    text: widget.person?.relationship ?? '',
  );
  late final _email = TextEditingController(text: widget.person?.email ?? '');
  late final _phone = TextEditingController(text: widget.person?.phone ?? '');
  late final _message = TextEditingController(
    text: widget.person?.message ?? '',
  );
  late final _groupIds = <String>{
    ...?widget.person?.groupIds,
    if (widget.person != null && widget.overview != null)
      for (final group in widget.overview!.groups)
        if (group.stakeholderIds.contains(widget.person!.id)) group.id,
  };
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(dataOverviewProvider);
    ref.invalidate(peopleOverviewProvider);
    ref.invalidate(homeSnapshotProvider);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || (email.isEmpty && phone.isEmpty)) {
      setState(() => _error = '이름과 이메일 또는 휴대폰 번호를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final value = Stakeholder(
      id: widget.person?.id ?? '',
      name: name,
      relationship: _relationship.text.trim(),
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
      message: _message.text.trim(),
      groupIds: _groupIds.toList(),
    );
    try {
      final repo = ref.read(stakeholderRepositoryProvider);
      if (widget.person == null) {
        await repo.create(value);
      } else {
        await repo.update(widget.person!.id, value);
      }
      _refresh();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final count = widget.overview?.accountCountFor(widget.person!.id) ?? 0;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('관계자를 삭제할까요?'),
        content: Text('이 관계자가 공개 대상인 데이터 $count개에 영향을 줄 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
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
      await ref.read(stakeholderRepositoryProvider).delete(widget.person!.id);
      _refresh();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAction(TransitionConfirmer? confirmer) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(transitionRepositoryProvider);
      if (confirmer == null) {
        await repo.invite(widget.person!);
      } else if (confirmer.status == ConfirmerStatus.pending) {
        await repo.resend(confirmer.id);
      } else {
        await repo.revoke(confirmer.id);
      }
      ref.invalidate(peopleOverviewProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmer = widget.person == null
        ? null
        : widget.overview?.confirmerFor(widget.person!.id);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(actionLabel: '저장', onAction: _busy ? null : _save),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    widget.person == null ? '관계자 추가' : '관계자 정보',
                    style: AppText.screenTitle,
                  ),
                  const SizedBox(height: 26),
                  AppTextField(label: '이름', controller: _name, hint: '이름'),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '관계',
                    controller: _relationship,
                    hint: '예: 가족, 친구',
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '이메일',
                    controller: _email,
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '휴대폰 번호',
                    controller: _phone,
                    hint: '01012345678',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '남길 메모',
                    controller: _message,
                    hint: '선택 사항',
                  ),
                  if (widget.overview?.groups.isNotEmpty == true) ...[
                    const SizedBox(height: 28),
                    Text('그룹', style: AppText.section),
                    for (final group in widget.overview!.groups)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          group.name,
                          style: AppText.body.copyWith(color: AppColors.ink),
                        ),
                        value: _groupIds.contains(group.id),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _groupIds.add(group.id);
                          } else {
                            _groupIds.remove(group.id);
                          }
                        }),
                      ),
                  ],
                  if (widget.person != null) ...[
                    const SizedBox(height: 24),
                    Text('사후 전환 확인자', style: AppText.section),
                    const SizedBox(height: 8),
                    Text(
                      confirmer == null
                          ? '아직 초대하지 않았어요.'
                          : _statusLabel(confirmer.status),
                      style: AppText.listCaption,
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _confirmAction(confirmer),
                      child: Text(
                        confirmer == null
                            ? '확인자로 초대'
                            : confirmer.status == ConfirmerStatus.pending
                            ? '초대 다시 보내기'
                            : '확인자에서 해제',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _delete,
                      child: const Text(
                        '관계자 삭제',
                        style: TextStyle(color: AppColors.unread),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.unread),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(label: '저장', busy: _busy, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(ConfirmerStatus status) => switch (status) {
    ConfirmerStatus.accepted => '초대 수락',
    ConfirmerStatus.pending => '초대 대기',
    ConfirmerStatus.declined => '초대 거절',
    ConfirmerStatus.expired => '초대 만료',
    ConfirmerStatus.revoked => '해제됨',
    ConfirmerStatus.unknown => '상태 확인 필요',
  };
}
