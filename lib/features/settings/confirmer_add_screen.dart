import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/stakeholder.dart';
import '../../data/providers.dart';
import 'settings_providers.dart';
import 'invitation_code_sheet.dart';

/// 19-2: pick confirmers from the stakeholders already saved.
class ConfirmerAddScreen extends ConsumerStatefulWidget {
  const ConfirmerAddScreen({super.key});

  @override
  ConsumerState<ConfirmerAddScreen> createState() => _ConfirmerAddScreenState();
}

class _ConfirmerAddScreenState extends ConsumerState<ConfirmerAddScreen> {
  final _selected = <String>{};
  var _submitting = false;

  Future<void> _submit(ConfirmerBoard board) async {
    final people = [
      for (final person in board.people)
        if (_selected.contains(person.id)) person,
    ];
    if (people.isEmpty) return;

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(transitionRepositoryProvider);
    try {
      for (final person in people) {
        final invitation = await repository.invite(person);
        if (!mounted) return;
        await showInvitationCodeSheet(context, invitation);
      }
      ref.invalidate(confirmerBoardProvider);
      ref.invalidate(settingsOverviewProvider);
      navigator.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      ref.invalidate(confirmerBoardProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(confirmerBoardProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('확인자 추가', style: AppText.screenTitle),
            ),
            Expanded(
              child: board.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error is ApiException ? error.message : '관계자를 불러오지 못했어요.',
                    style: AppText.body,
                  ),
                ),
                data: (data) => _body(data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ConfirmerBoard data) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              Text('등록된 관계자 중 확인자를 선택하세요.', style: AppText.paragraph),
              const SizedBox(height: 16),
              if (data.people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '등록된 관계자가 없어요. 관계자 탭에서 먼저 추가해 주세요.',
                    style: AppText.body,
                  ),
                )
              else
                for (final person in data.people)
                  _PersonRow(
                    person: person,
                    assigned: data.isAssigned(person),
                    selected: _selected.contains(person.id),
                    onTap: () => setState(() {
                      if (!_selected.remove(person.id)) {
                        _selected.add(person.id);
                      }
                    }),
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            children: [
              PrimaryButton(
                label: _selected.isEmpty
                    ? '관계자를 선택해 주세요'
                    : '${_selected.length}명 확인자로 추가',
                enabled: _selected.isNotEmpty,
                busy: _submitting,
                onPressed: () => _submit(data),
              ),
              const SizedBox(height: 12),
              Text('확인자로 추가해도 데이터 열람 권한은 바뀌지 않습니다.', style: AppText.helper),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.assigned,
    required this.selected,
    required this.onTap,
  });

  final Stakeholder person;
  final bool assigned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final relation = person.relationship?.isNotEmpty == true
        ? person.relationship!
        : '관계 미지정';
    return InkWell(
      onTap: assigned ? null : onTap,
      child: Container(
        height: 75,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.listDivider)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.avatarMuted,
              child: Text(
                person.name.isEmpty ? '?' : person.name[0],
                style: AppText.section,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: AppText.section),
                  const SizedBox(height: 3),
                  Text(relation, style: AppText.listCaption),
                ],
              ),
            ),
            Text(
              assigned
                  ? '지정됨'
                  : selected
                  ? '선택됨'
                  : '선택',
              style: AppText.body.copyWith(
                color: assigned
                    ? AppColors.brand
                    : selected
                    ? AppColors.inkDeep
                    : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
