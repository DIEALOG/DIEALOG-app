import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/account.dart';
import '../../../data/providers.dart';
import '../../shared/audience_picker.dart';
import '../../settings/settings_providers.dart';
import '../legacy_providers.dart';

/// `사후 열람`: who the account opens to, and where that comes from.
class AccountAudienceSection extends ConsumerWidget {
  const AccountAudienceSection({
    super.key,
    required this.account,
    this.selection,
  });

  final Account account;
  final AudienceSelection? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dataOverviewProvider).asData?.value;
    final people = {
      for (final person in account.stakeholders) person.id: person,
      for (final group in account.stakeholderGroups)
        for (final person in group.stakeholders) person.id: person,
      ...?overview?.people,
    };
    final groups = {
      for (final group in account.stakeholderGroups) group.id: group,
      ...?overview?.groups,
    };
    final personIds =
        selection?.people ??
        {
          ...account.stakeholderIds,
          for (final person in account.stakeholders) person.id,
        };
    final groupIds =
        selection?.groups ??
        {
          ...account.stakeholderGroupIds,
          for (final group in account.stakeholderGroups) group.id,
        };
    final ids = <String>{...personIds};
    for (final groupId in groupIds) {
      final group = groups[groupId];
      if (group != null) {
        ids.addAll(group.stakeholderIds);
        ids.addAll(group.stakeholders.map((person) => person.id));
      }
    }
    ids.remove('');
    final names = [for (final id in ids) people[id]?.name ?? '이름 미확인'];
    final sources = [
      for (final id in groupIds) groups[id]?.name ?? '그룹',
      for (final id in personIds) people[id]?.name ?? '관계자',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('사후 열람', style: AppText.listTitle),
            const Spacer(),
            Text(
              '${ids.length}명',
              style: AppText.listTitle.copyWith(color: AppColors.inkDeep),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          ids.isEmpty ? '아직 공개 대상을 지정하지 않았어요.' : names.join(', '),
          style: AppText.rowValue.copyWith(height: 22.5 / 15),
        ),
        if (sources.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('${sources.join(', ')} 지정', style: AppText.listCaption),
        ],
      ],
    );
  }
}

/// `계정 정보`: login id, password behind a reveal, and where the data sits.
class AccountInfoSection extends ConsumerStatefulWidget {
  const AccountInfoSection({super.key, required this.account, this.error});

  final Account account;

  /// Set when the credentials could not be read; shown in place of the rows.
  final String? error;

  @override
  ConsumerState<AccountInfoSection> createState() => _AccountInfoSectionState();
}

class _AccountInfoSectionState extends ConsumerState<AccountInfoSection> {
  var _revealed = false;

  Future<void> _toggleSecret() async {
    if (_revealed) {
      setState(() => _revealed = false);
      return;
    }
    final settings = ref.read(localSettingsProvider).value;
    if (settings?.certifyBeforeSensitive == true) {
      final ok = await ref
          .read(biometricAuthProvider)
          .authenticate('계정 비밀번호를 보려면 인증이 필요해요.');
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('인증하지 못했어요.')));
        }
        return;
      }
    }
    if (mounted) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final loginId = account.accountId;
    final password = account.accountPassword;
    final location = account.dataLocation;

    if (widget.error == null &&
        loginId == null &&
        password == null &&
        location == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('계정 정보', style: AppText.listTitle),
        const SizedBox(height: 18),
        if (widget.error != null)
          Text(
            '${widget.error}\n계정 정보는 잠시 후 다시 확인해 주세요.',
            style: AppText.helper,
          ),
        if (loginId != null)
          _InfoRow(
            label: loginId.contains('@') ? '이메일' : '계정 ID',
            value: Text(loginId, style: AppText.rowValue),
          ),
        if (password != null)
          _InfoRow(
            label: '비밀번호',
            height: 56,
            value: Text(
              _revealed ? password : '•' * 8,
              style: AppText.rowValue,
            ),
            trailing: TextButton(
              onPressed: _toggleSecret,
              style: TextButton.styleFrom(
                minimumSize: const Size(34, 22),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.inkDeep,
              ),
              child: Text(
                _revealed ? '숨기기' : '보기',
                style: AppText.headerAction.copyWith(fontSize: 14),
              ),
            ),
          ),
        if (location != null)
          _InfoRow(
            label: '자료 위치',
            value: Text(
              location,
              style: AppText.rowValue.copyWith(
                fontWeight: FontWeight.w400,
                height: 22.5 / 15,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
    this.height = 50,
  });

  final String label;
  final Widget value;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 76, child: Text(label, style: AppText.rowLabel)),
          const SizedBox(width: 20),
          Expanded(child: value),
          ?trailing,
        ],
      ),
    );
  }
}
