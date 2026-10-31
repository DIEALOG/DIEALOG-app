import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/stakeholder.dart';

/// Keeps group and individual ids distinct while counting each recipient once.
class AudienceSelection {
  const AudienceSelection({this.people = const {}, this.groups = const {}});

  final Set<String> people;
  final Set<String> groups;

  Set<String> resolvedIds(Iterable<StakeholderGroup> availableGroups) {
    final selected = <String>{...people};
    for (final group in availableGroups) {
      if (groups.contains(group.id)) selected.addAll(group.stakeholderIds);
    }
    return selected;
  }

  AudienceSelection toggleGroup(
    StakeholderGroup group,
    Iterable<StakeholderGroup> availableGroups,
  ) {
    final allSelected =
        group.stakeholderIds.isNotEmpty &&
        resolvedIds(availableGroups).containsAll(group.stakeholderIds);
    final nextGroups = <String>{...groups};
    final nextPeople = <String>{...people};
    if (allSelected) {
      nextGroups.remove(group.id);
      nextPeople.removeAll(group.stakeholderIds);
    } else {
      nextGroups.add(group.id);
      nextPeople.removeAll(group.stakeholderIds);
    }
    return AudienceSelection(people: nextPeople, groups: nextGroups);
  }

  AudienceSelection togglePerson(
    String personId,
    Iterable<StakeholderGroup> availableGroups,
  ) {
    final selected = resolvedIds(availableGroups).contains(personId);
    final nextGroups = <String>{...groups};
    final nextPeople = <String>{...people};
    if (selected) {
      for (final group in availableGroups) {
        if (group.stakeholderIds.contains(personId) &&
            nextGroups.remove(group.id)) {
          nextPeople.addAll(group.stakeholderIds);
        }
      }
      nextPeople.remove(personId);
    } else {
      nextPeople.add(personId);
    }
    return AudienceSelection(people: nextPeople, groups: nextGroups);
  }
}

class AudiencePicker extends StatelessWidget {
  const AudiencePicker({
    super.key,
    required this.people,
    required this.groups,
    required this.selection,
    required this.onChanged,
  });

  final List<Stakeholder> people;
  final List<StakeholderGroup> groups;
  final AudienceSelection selection;
  final ValueChanged<AudienceSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selection.resolvedIds(groups);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (groups.isNotEmpty) ...[
          Text(
            '그룹 선택',
            style: AppText.formLabel.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          for (final group in groups)
            _ChoiceRow(
              title: group.name,
              subtitle: group.stakeholderIds
                  .map(
                    (id) => people.where((p) => p.id == id).firstOrNull?.name,
                  )
                  .whereType<String>()
                  .join(', '),
              value: group.stakeholderIds.isEmpty
                  ? false
                  : selected.containsAll(group.stakeholderIds)
                  ? true
                  : group.stakeholderIds.any(selected.contains)
                  ? null
                  : false,
              onTap: () => onChanged(selection.toggleGroup(group, groups)),
            ),
        ],
        if (people.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '개인 선택',
            style: AppText.formLabel.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          for (final person in people)
            _ChoiceRow(
              title: person.name,
              subtitle: person.relationship ?? '',
              value: selected.contains(person.id),
              onTap: () => onChanged(selection.togglePerson(person.id, groups)),
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
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            tristate: true,
            onChanged: (_) => onTap(),
            visualDensity: VisualDensity.compact,
            activeColor: AppColors.navy,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppText.rowValue),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.listCaption,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
