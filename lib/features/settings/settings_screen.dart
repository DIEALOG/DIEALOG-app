import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/profile.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../afterlife/afterlife_screen.dart';
import 'profile_screen.dart';

final settingsProfileProvider = FutureProvider.autoDispose<Profile>(
  (ref) => ref.watch(profileRepositoryProvider).fetch(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(settingsProfileProvider);
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
          child: profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(settingsProfileProvider),
                child: const Text('프로필을 불러오지 못했어요. 다시 시도'),
              ),
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.inkDeep,
                        child: Text(
                          data.name.isEmpty ? '?' : data.name.substring(0, 1),
                          style: AppText.section.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.name, style: AppText.section),
                            Text(data.email, style: AppText.listCaption),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('보안', style: AppText.section),
                const SizedBox(height: 8),
                const _UnavailableSetting('Face ID로 앱 잠금'),
                const _UnavailableSetting('민감한 정보 보기 전 본인 인증'),
                const SizedBox(height: 8),
                Text('설정 상태 조회 API가 준비되면 사용할 수 있어요.', style: AppText.helper),
                const SizedBox(height: 32),
                Text('사후 기록', style: AppText.section),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('맡은 기록과 받은 말'),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AfterlifeScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('계정', style: AppText.section),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('로그아웃'),
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnavailableSetting extends StatelessWidget {
  const _UnavailableSetting(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: AppText.body.copyWith(color: AppColors.ink)),
    trailing: const Text('준비 중', style: TextStyle(color: AppColors.muted)),
  );
}
