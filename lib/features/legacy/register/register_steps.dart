import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/account.dart';
import '../../shared/audience_picker.dart';
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
        FieldLabel('상세 지침', optional: kind != AccountActionKind.other),
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
class AudienceStep extends ConsumerWidget {
  const AudienceStep({
    super.key,
    required this.people,
    required this.groups,
    required this.onChanged,
  });

  final Set<String> people;
  final Set<String> groups;
  final ValueChanged<AudienceSelection> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      data: (data) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('누가 볼 수 있을까요?', style: AppText.screenTitle),
            ),
          ),
          Expanded(
            child: AudiencePicker(
              people: data.people.values.toList(),
              groups: data.groups.values.toList(),
              selection: AudienceSelection(people: people, groups: groups),
              onChanged: onChanged,
            ),
          ),
        ],
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
        _SummaryRow(label: '처리 방식', value: account.action?.kind.label ?? '-'),
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
                Text(entry.key, style: AppText.rowValue.copyWith(fontSize: 14)),
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
          SizedBox(width: 76, child: Text(label, style: AppText.rowLabel)),
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
