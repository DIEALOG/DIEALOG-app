import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/stakeholder.dart';
import '../../data/providers.dart';
import '../home/home_screen.dart';
import '../legacy/legacy_providers.dart';
import 'people_providers.dart';

class GroupEditScreen extends ConsumerStatefulWidget {
  const GroupEditScreen({super.key, this.group, required this.overview});

  final StakeholderGroup? group;
  final PeopleOverview overview;

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  late final _name = TextEditingController(text: widget.group?.name ?? '');
  late final _selected = <String>{...?widget.group?.stakeholderIds};
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(dataOverviewProvider);
    ref.invalidate(peopleOverviewProvider);
    ref.invalidate(homeSnapshotProvider);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '그룹 이름을 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final value = StakeholderGroup(
      id: widget.group?.id ?? '',
      name: name,
      stakeholderIds: _selected.toList(),
    );
    try {
      final repo = ref.read(stakeholderRepositoryProvider);
      if (widget.group == null) {
        await repo.createGroup(value);
      } else {
        await repo.updateGroup(widget.group!.id, value);
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
    final count = widget.overview.accountCountForGroup(widget.group!.id);
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('그룹을 삭제할까요?'),
        content: Text('이 그룹이 공개 대상인 데이터 $count개에 영향을 줄 수 있어요.'),
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
      await ref
          .read(stakeholderRepositoryProvider)
          .deleteGroup(widget.group!.id);
      _refresh();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          ScreenHeader(actionLabel: '저장', onAction: _busy ? null : _save),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  widget.group == null ? '그룹 추가' : '그룹 편집',
                  style: AppText.screenTitle,
                ),
                const SizedBox(height: 26),
                AppTextField(label: '그룹 이름', controller: _name, hint: '예: 가족'),
                const SizedBox(height: 28),
                Text('관계자 선택', style: AppText.section),
                const SizedBox(height: 8),
                if (widget.overview.people.isEmpty)
                  Text('먼저 관계자를 추가해 주세요.', style: AppText.body),
                for (final person in widget.overview.people)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      person.name,
                      style: AppText.body.copyWith(color: AppColors.ink),
                    ),
                    subtitle: Text(
                      person.relationship ?? '',
                      style: AppText.listCaption,
                    ),
                    value: _selected.contains(person.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(person.id);
                      } else {
                        _selected.remove(person.id);
                      }
                    }),
                  ),
                if (widget.group != null) ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    child: const Text(
                      '그룹 삭제',
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
