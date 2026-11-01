import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../../data/models/stakeholder.dart';
import '../../data/models/transition_confirmer.dart';
import '../transition/confirmer_cases_screen.dart';
import 'group_edit_screen.dart';
import 'people_providers.dart';
import 'stakeholder_edit_screen.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(peopleOverviewProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Text('관계자', style: AppText.screenTitle),
              const Spacer(),
              IconButton(
                tooltip: '관계자 추가',
                onPressed: () =>
                    _openPerson(context, ref, null, snapshot.asData?.value),
                icon: const AppIcon('assets/icons/icon_plus.svg', size: 24),
              ),
            ],
          ),
        ),
        Expanded(
          child: snapshot.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException ? error.message : '관계자를 불러오지 못했어요.',
                    style: AppText.body,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(peopleOverviewProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.refresh(peopleOverviewProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text(
                    '${data.people.length}명 · 그룹 ${data.groups.length}개',
                    style: AppText.greeting,
                  ),
                  const SizedBox(height: 26),
                  _RequestEntry(),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text('사후 전환 확인자', style: AppText.section),
                      const Spacer(),
                      Text(
                        '${data.activeConfirmers.where((item) => item.status == ConfirmerStatus.accepted).length} / ${data.activeConfirmers.length}',
                        style: AppText.listCaption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (data.activeConfirmers.isEmpty)
                    Text('등록된 확인자가 없어요.', style: AppText.listCaption)
                  else
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: [
                        for (final item in data.activeConfirmers)
                          Text(
                            '${item.name}  ${_relationship(data, item)}',
                            style: AppText.listCaption.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 28),
                  Text('처리 관계자', style: AppText.section),
                  if (data.people.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text('아직 등록한 관계자가 없어요.', style: AppText.body),
                    ),
                  for (final person in data.people)
                    _PersonRow(
                      person: person,
                      accountCount: data.accountCountFor(person.id),
                      confirmer: data.confirmerFor(person.id),
                      onTap: () => _openPerson(context, ref, person, data),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('그룹', style: AppText.section),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _openGroup(context, ref, null, data),
                        child: const Text('+ 그룹 추가'),
                      ),
                    ],
                  ),
                  if (data.groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('아직 만든 그룹이 없어요.', style: AppText.body),
                    ),
                  for (final group in data.groups)
                    _GroupRow(
                      group: group,
                      members: data.membersOf(group),
                      accountCount: data.accountCountForGroup(group.id),
                      onTap: () => _openGroup(context, ref, group, data),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _relationship(PeopleOverview data, TransitionConfirmer item) =>
      data.data.people[item.stakeholderId]?.relationship ?? '';

  static Future<void> _openPerson(
    BuildContext context,
    WidgetRef ref,
    Stakeholder? person,
    PeopleOverview? data,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StakeholderEditScreen(person: person, overview: data),
      ),
    );
    ref.invalidate(peopleOverviewProvider);
  }

  static Future<void> _openGroup(
    BuildContext context,
    WidgetRef ref,
    StakeholderGroup? group,
    PeopleOverview data,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupEditScreen(group: group, overview: data),
      ),
    );
    ref.invalidate(peopleOverviewProvider);
  }
}

class _RequestEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ConfirmerCasesScreen()),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내게 온 요청',
                  style: AppText.listTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '나를 확인자로 지정한 사람과 사후 전환 요청을 확인해요.',
                  style: AppText.listCaption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
        ],
      ),
    ),
  );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.accountCount,
    required this.confirmer,
    required this.onTap,
  });

  final Stakeholder person;
  final int accountCount;
  final TransitionConfirmer? confirmer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 61,
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
                Text(
                  '${person.relationship?.isNotEmpty == true ? person.relationship : '관계 미지정'} · 데이터 $accountCount개',
                  style: AppText.listCaption,
                ),
              ],
            ),
          ),
          if (confirmer?.status == ConfirmerStatus.pending)
            Text('초대 대기', style: AppText.listCaption),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
        ],
      ),
    ),
  );
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.members,
    required this.accountCount,
    required this.onTap,
  });

  final StakeholderGroup group;
  final List<Stakeholder> members;
  final int accountCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.listDivider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(group.name, style: AppText.section)),
              Text(
                '${members.length}명 · 데이터 $accountCount개',
                style: AppText.listCaption,
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.chevron,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            members.map((person) => person.name).join(', '),
            style: AppText.body.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    ),
  );
}
