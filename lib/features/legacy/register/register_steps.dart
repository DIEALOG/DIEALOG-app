import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/account.dart';
import '../../../data/models/stakeholder.dart';
import '../legacy_providers.dart';
import '../widgets/form_fields.dart';
import '../widgets/service_sheet.dart';

/// `10-1 · 기본 정보`
class BasicsStep extends StatelessWidget {
  const BasicsStep({
    super.key,
    required this.choice,
    required this.customService,
    required this.name,
    required this.accountId,
    required this.password,
    required this.dataLocation,
    required this.onPickService,
    required this.onChanged,
  });

  final ServiceChoice? choice;
  final TextEditingController customService;
  final TextEditingController name;
  final TextEditingController accountId;
  final TextEditingController password;
  final TextEditingController dataLocation;
  final VoidCallback onPickService;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text('어떤 계정인가요?', style: AppText.screenTitle),
        const SizedBox(height: 20),
        SelectField(
          label: '서비스',
          value: choice?.label,
          placeholder: '서비스를 선택해 주세요',
          onTap: onPickService,
        ),
        if (choice?.custom ?? false) ...[
          const SizedBox(height: 12),
          AppFormField(
            controller: customService,
            hint: '서비스 이름을 적어 주세요',
            onChanged: (_) => onChanged(),
          ),
        ],
        const SizedBox(height: 20),
        AppFormField(
          label: '계정·데이터 이름',
          controller: name,
          hint: '예: 개인 계정, 가족사진',
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        AppFormField(
          label: '아이디·이메일',
          optional: true,
          controller: accountId,
          hint: '로그인 아이디',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        AppFormField(
          label: '비밀번호',
          optional: true,
          controller: password,
          hint: '필요한 경우에만',
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        AppFormField(
          label: '자료 위치',
          optional: true,
          controller: dataLocation,
          hint: '폴더 경로나 링크',
        ),
      ],
    );
  }
}

/// `11 · 처리 지침 · 방식 선택`
class ActionStep extends StatelessWidget {
  const ActionStep({
    super.key,
    required this.kind,
    required this.message,
    required this.onPickKind,
  });

  final AccountActionKind? kind;
  final TextEditingController message;
  final VoidCallback onPickKind;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text('어떻게 정리할까요?', style: AppText.screenTitle),
        const SizedBox(height: 20),
        SelectField(
          label: '처리 방식',
          value: kind?.label,
          placeholder: '처리 방식을 선택해 주세요',
          onTap: onPickKind,
        ),
        const SizedBox(height: 36),
        FieldLabel(
          '상세 지침',
          optional: kind != AccountActionKind.other,
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.inputLine),
          ),
          child: TextField(
            controller: message,
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
        ),
      ],
    );
  }
}

/// `12 · 공개 대상 선택`
class AudienceStep extends ConsumerStatefulWidget {
  const AudienceStep({
    super.key,
    required this.people,
    required this.groups,
    required this.onTogglePerson,
    required this.onToggleGroup,
  });

  final Set<String> people;
  final Set<String> groups;
  final ValueChanged<String> onTogglePerson;
  final ValueChanged<String> onToggleGroup;

  @override
  ConsumerState<AudienceStep> createState() => _AudienceStepState();
}

class _AudienceStepState extends ConsumerState<AudienceStep> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(dataOverviewProvider);
    return overview.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e is ApiException ? e.message : '관계자를 불러오지 못했어요.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (data) {
        final groups = data.groups.values.toList();
        final people = data.people.values.toList();
        // A person's group is shown on the right of their row.
        final groupOf = <String, String>{
          for (final group in groups)
            for (final id in group.stakeholderIds) id: group.name,
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text('누가 볼 수 있을까요?', style: AppText.screenTitle),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '그룹',
                style: AppText.formLabel.copyWith(color: AppColors.muted),
              ),
              for (final group in groups)
                _GroupRow(
                  group: group,
                  checked: widget.groups.contains(group.id),
                  expanded: _expanded.contains(group.id),
                  onTap: () => widget.onToggleGroup(group.id),
                  onToggleExpanded: () => setState(() {
                    if (!_expanded.remove(group.id)) _expanded.add(group.id);
                  }),
                ),
            ],
            if (people.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '개인',
                style: AppText.formLabel.copyWith(color: AppColors.muted),
              ),
              for (final person in people)
                _PersonRow(
                  person: person,
                  group: groupOf[person.id],
                  checked: widget.people.contains(person.id),
                  onTap: () => widget.onTogglePerson(person.id),
                ),
            ],
            if (groups.isEmpty && people.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  '아직 등록한 관계자가 없어요.\n관계자 탭에서 먼저 추가해 주세요.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.checked,
    required this.expanded,
    required this.onTap,
    required this.onToggleExpanded,
  });

  final StakeholderGroup group;
  final bool checked;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final members = [for (final s in group.stakeholders) s.name];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        AppCheckbox(checked: checked),
                        const SizedBox(width: 12),
                        Text(group.name, style: AppText.rowValue),
                        const SizedBox(width: 12),
                        Text(
                          '${group.stakeholderIds.length}명',
                          style: AppText.rowLabel.copyWith(letterSpacing: 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (members.isNotEmpty)
                TextButton(
                  onPressed: onToggleExpanded,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    foregroundColor: AppColors.ink,
                  ),
                  child: Text(
                    expanded ? '접기' : '구성원 보기',
                    style: AppText.listCaption.copyWith(color: AppColors.ink),
                  ),
                ),
            ],
          ),
          if (expanded && members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 13),
              child: Text(
                members.join(', '),
                style: AppText.rowLabel.copyWith(height: 22.4 / 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.checked,
    required this.onTap,
    this.group,
  });

  final Stakeholder person;
  final String? group;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            AppCheckbox(checked: checked),
            const SizedBox(width: 12),
            Text(person.name, style: AppText.rowValue),
            if ((person.relationship ?? '').isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  person.relationship!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.listCaption,
                ),
              ),
            ],
            const Spacer(),
            if (group != null)
              Text(
                group!,
                style: AppText.listCaption.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

/// `13 · 공개 대상 확인`
class ConfirmStep extends ConsumerWidget {
  const ConfirmStep({
    super.key,
    required this.account,
    required this.serviceLabel,
    required this.people,
    required this.groups,
  });

  final Account account;
  final String serviceLabel;
  final Set<String> people;
  final Set<String> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dataOverviewProvider).value;
    // name -> where the access comes from
    final audience = <String, String>{};
    if (overview != null) {
      for (final id in groups) {
        final group = overview.groups[id];
        if (group == null) continue;
        for (final member in group.stakeholders) {
          audience[member.name] = group.name;
        }
      }
      for (final id in people) {
        final person = overview.people[id];
        if (person != null) audience[person.name] = '개인 지정';
      }
    }
    final message = account.action?.message ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text('이대로 저장할까요?', style: AppText.screenTitle),
        const SizedBox(height: 20),
        _SummaryRow(label: '서비스', value: serviceLabel),
        _SummaryRow(label: '계정·데이터', value: account.name),
        _SummaryRow(
          label: '처리 방식',
          value: account.action?.kind.label ?? '-',
        ),
        if (message.isNotEmpty) _SummaryRow(label: '지침', value: message),
        const SizedBox(height: 26),
        Row(
          children: [
            Text('사후 공개 시 열람', style: AppText.listTitle),
            const Spacer(),
            Text(
              '${audience.length}명',
              style: AppText.listTitle.copyWith(color: AppColors.inkDeep),
            ),
          ],
        ),
        for (final entry in audience.entries)
          Container(
            height: 38,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Text(
                  entry.key,
                  style: AppText.rowValue.copyWith(fontSize: 14),
                ),
                const Spacer(),
                Text(entry.value, style: AppText.listCaption),
              ],
            ),
          ),
        if (audience.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('공개 대상을 지정하지 않았어요.', style: AppText.helper),
          ),
        const SizedBox(height: 20),
        Text(
          '사후 전환 확인자라는 이유만으로는 이 정보를 볼 수 없어요.',
          style: AppText.listCaption.copyWith(height: 20.8 / 13),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: AppText.rowLabel),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              style: AppText.rowValue.copyWith(
                fontWeight: FontWeight.w400,
                height: 23.25 / 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
