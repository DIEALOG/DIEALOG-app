import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/local_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../afterlife/afterlife_screen.dart';
import '../auth/auth_controller.dart';
import 'confirmers_screen.dart';
import 'policy_sheets.dart';
import 'profile_screen.dart';
import 'settings_providers.dart';
import '../transition/invitation_screen.dart';
import '../transition/confirmer_cases_screen.dart';
import '../transition/owner_transition_screen.dart';
import '../transition/stakeholder_task_result_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(settingsOverviewProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('설정', style: AppText.screenTitle),
          ),
        ),
        Expanded(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException ? error.message : '설정을 불러오지 못했어요.',
                    style: AppText.body,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(settingsOverviewProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (data) => _Body(data: data),
          ),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final SettingsOverview data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local =
        ref.watch(localSettingsProvider).value ?? const LocalSettings();
    final controller = ref.read(localSettingsProvider.notifier);
    final policy = data.policy;

    Future<void> saveSecurity(LocalSettings next) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await controller.saveSecurity(next);
      } on ApiException catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('서버에 반영하지 못했어요. ${e.message}')),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(settingsOverviewProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProfileRow(
            name: data.profile.name,
            email: data.profile.email,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
              ref.invalidate(settingsOverviewProvider);
            },
          ),
          const _SectionLabel('보안'),
          _SwitchRow(
            label: 'Face ID로 앱 잠금',
            value: local.lockByFaceId,
            onChanged: (v) => saveSecurity(local.copyWith(lockByFaceId: v)),
          ),
          _SwitchRow(
            label: '민감 정보 볼 때 다시 인증',
            value: local.certifyBeforeSensitive,
            onChanged: (v) =>
                saveSecurity(local.copyWith(certifyBeforeSensitive: v)),
          ),
          const _SectionLabel('사후 공개'),
          _ValueRow(
            label: '사후 전환 확인자',
            value: '${data.acceptedCount}명',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConfirmersScreen(),
                ),
              );
              ref.invalidate(settingsOverviewProvider);
            },
          ),
          _ValueRow(
            label: '전환 기준',
            value: policy.summary,
            onTap: () => showTransitionCriteriaSheet(context, policy),
          ),
          _ValueRow(
            label: '생존 확인 주기',
            value: '${policy.aliveCheckIntervalDays}일',
            onTap: () => showAliveCheckIntervalSheet(context, policy),
          ),
          _ValueRow(
            label: '사후 전환 상태와 생존 확인',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OwnerTransitionScreen(),
              ),
            ),
          ),
          const _SectionLabel('알림'),
          _SwitchRow(
            label: '사후 전환 요청',
            value: local.notifyTransitionRequest,
            onChanged: (v) =>
                controller.save(local.copyWith(notifyTransitionRequest: v)),
          ),
          _SwitchRow(
            label: '맡은 기록 진행 상황',
            value: local.notifyEntrustedProgress,
            onChanged: (v) =>
                controller.save(local.copyWith(notifyEntrustedProgress: v)),
          ),
          _SwitchRow(
            label: '남기는 말 임시 저장 알림',
            value: local.notifyLetterDraft,
            onChanged: (v) =>
                controller.save(local.copyWith(notifyLetterDraft: v)),
          ),
          const SizedBox(height: 8),
          Text('알림 발송은 아직 준비 중이라, 선택은 이 기기에만 저장돼요.', style: AppText.helper),
          const _SectionLabel('사후 기록'),
          _ValueRow(
            label: '맡은 기록과 받은 말',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AfterlifeScreen()),
            ),
          ),
          _ValueRow(
            label: '확인자 초대 코드 입력',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const InvitationScreen()),
            ),
          ),
          _ValueRow(
            label: '내게 온 사후 전환 요청',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConfirmerCasesScreen(),
              ),
            ),
          ),
          _ValueRow(
            label: '계정 처리 결과 제출',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StakeholderTaskResultScreen(),
              ),
            ),
          ),
          const _SectionLabel('계정'),
          _ValueRow(
            label: '로그아웃',
            showChevron: false,
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String name;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.listDivider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.inkDeep,
            child: Text(
              name.isEmpty ? '?' : name[0],
              style: AppText.section.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('프로필 설정', style: AppText.section),
                const SizedBox(height: 3),
                Text(
                  [name, email].where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.listCaption,
                  overflow: TextOverflow.ellipsis,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
    child: Text(text, style: AppText.helper),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.listDivider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.body.copyWith(color: AppColors.ink),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.navy,
        ),
      ],
    ),
  );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.onTap,
    this.value,
    this.showChevron = true,
  });

  final String label;
  final String? value;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.listDivider)),
      ),
      child: Row(
        children: [
          Text(label, style: AppText.body.copyWith(color: AppColors.ink)),
          const SizedBox(width: 12),
          // The value takes the rest of the row so summaries like
          // "확인자 2명 동의 + 14일 대기" stay readable.
          Expanded(
            child: Text(
              value ?? '',
              style: AppText.listCaption,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
          ],
        ],
      ),
    ),
  );
}
