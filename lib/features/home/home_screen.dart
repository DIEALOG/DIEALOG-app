import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../../data/models/last_word.dart';
import '../../data/models/legacy.dart';
import '../../data/models/profile.dart';
import '../../data/models/stakeholder.dart';
import '../../data/models/transition_confirmer.dart';
import '../../data/providers.dart';
import '../../data/repositories/entrusted_repository.dart';
import '../afterlife/afterlife_screen.dart';
import '../legacy/legacy_providers.dart';
import '../last_word/letter_edit_screen.dart';
import '../last_word/letter_providers.dart';
import '../notifications/notification_providers.dart';
import '../settings/profile_screen.dart';
import '../stakeholder/people_providers.dart';
import '../stakeholder/stakeholder_edit_screen.dart';
import 'greeting.dart';

class HomeSnapshot {
  const HomeSnapshot({
    required this.profile,
    required this.legacies,
    required this.stakeholders,
    required this.groups,
    required this.lastWords,
    required this.entrusted,
    required this.confirmers,
  });

  final Profile profile;
  final List<Legacy> legacies;
  final List<Stakeholder> stakeholders;
  final List<StakeholderGroup> groups;
  final List<LastWord> lastWords;
  final List<EntrustedOwner> entrusted;
  final List<TransitionConfirmer> confirmers;
}

final homeSnapshotProvider = FutureProvider.autoDispose<HomeSnapshot>((
  ref,
) async {
  final stakeholders = ref.watch(stakeholderRepositoryProvider);
  final results = await Future.wait<Object>([
    ref.watch(profileRepositoryProvider).fetch(),
    ref.watch(legacyRepositoryProvider).list(),
    stakeholders.list(),
    stakeholders.listGroups(),
    ref.watch(lastWordRepositoryProvider).list(),
    ref.watch(entrustedRepositoryProvider).listOwners().onError(
      (error, stackTrace) => <EntrustedOwner>[],
    ),
    ref.watch(transitionRepositoryProvider).listConfirmers(),
  ]);
  return HomeSnapshot(
    profile: results[0] as Profile,
    legacies: results[1] as List<Legacy>,
    stakeholders: results[2] as List<Stakeholder>,
    groups: results[3] as List<StakeholderGroup>,
    lastWords: results[4] as List<LastWord>,
    entrusted: results[5] as List<EntrustedOwner>,
    confirmers: results[6] as List<TransitionConfirmer>,
  );
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(homeSnapshotProvider);
    return snap.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              e is ApiException ? e.userMessage : '홈을 불러오지 못했어요.',
              style: AppText.body,
            ),
            TextButton(
              onPressed: () => ref.invalidate(homeSnapshotProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (data) => _HomeBody(data: data, onSelectTab: onSelectTab),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data, required this.onSelectTab});

  final HomeSnapshot data;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = data.profile.profileImagePath;
    final imageUrl = imagePath == null || imagePath.isEmpty
        ? null
        : Uri.parse(Env.apiBaseUrl)
              .resolve(imagePath.startsWith('/') ? imagePath : '/$imagePath')
              .toString();
    final accounts = data.legacies.expand((l) => l.accounts).toList();
    final groups = {for (final group in data.groups) group.id: group};
    final assigned = accounts
        .where((a) => audienceOf(a, groups).isNotEmpty)
        .length;
    final unassigned = accounts
        .where((a) => audienceOf(a, groups).isEmpty)
        .toList();
    final letters = data.lastWords.length;
    final unaddressed = [
      for (final word in data.lastWords)
        if (word.receiverIds.isEmpty && word.receiverGroupIds.isEmpty) word,
    ];
    final confirmers = data.confirmers
        .where((item) => item.status == ConfirmerStatus.accepted)
        .length;
    final todos = <_Todo>[
      if (unassigned.isNotEmpty)
        _Todo(
          icon: 'assets/icons/icon_list_data.svg',
          title: unassigned.length == 1
              ? unassigned.single.name
              : '공개 대상 미지정 데이터',
          caption: '공개 대상 미지정',
          onTap: () async {
            if (unassigned.length != 1) {
              onSelectTab(1);
              return;
            }
            final account = unassigned.single;
            final legacy = data.legacies.firstWhere(
              (item) => item.accounts.any((entry) => entry.id == account.id),
            );
            await context.push(Routes.accountDetailOf(legacy.id, account.id));
            ref.invalidate(homeSnapshotProvider);
          },
        ),
      if (data.stakeholders.any(
        (s) =>
            (s.email?.trim().isEmpty ?? true) &&
            (s.phone?.trim().isEmpty ?? true),
      ))
        _Todo(
          icon: 'assets/icons/icon_list_people.svg',
          title:
              '${data.stakeholders.firstWhere((s) => (s.email?.trim().isEmpty ?? true) && (s.phone?.trim().isEmpty ?? true)).name} 님',
          caption: '연락처 미입력',
          onTap: () async {
            final person = data.stakeholders.firstWhere(
              (s) =>
                  (s.email?.trim().isEmpty ?? true) &&
                  (s.phone?.trim().isEmpty ?? true),
            );
            try {
              final overview = await ref.read(peopleOverviewProvider.future);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StakeholderEditScreen(person: person, overview: overview),
                ),
              );
              ref.invalidate(homeSnapshotProvider);
            } catch (_) {
              onSelectTab(2);
            }
          },
        ),
      if (unaddressed.isNotEmpty)
        _Todo(
          icon: 'assets/icons/icon_list_letters.svg',
          title: '‘${_ellipsis(unaddressed.first.title, 12)}’',
          caption: '받는 사람 미지정',
          onTap: () async {
            try {
              final overview = await ref.read(letterOverviewProvider.future);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LetterEditScreen(
                    overview: overview,
                    letter: unaddressed.first,
                  ),
                ),
              );
              ref.invalidate(homeSnapshotProvider);
              ref.invalidate(letterOverviewProvider);
            } catch (_) {
              onSelectTab(3);
            }
          },
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(homeSnapshotProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Header(
            name: data.profile.name,
            imageUrl: imageUrl,
            onOpenProfile: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
              ref.invalidate(homeSnapshotProvider);
            },
          ),
          const SizedBox(height: 24),
          _SummaryCard(
            accountCount: accounts.length,
            assigned: assigned,
            total: accounts.length,
            letters: letters,
            people: data.stakeholders.length,
            confirmers: confirmers,
            onOpenData: () => onSelectTab(1),
            onOpenLetters: () => onSelectTab(3),
            onOpenPeople: () => onSelectTab(2),
          ),
          if (data.entrusted.any((o) => o.hasAnything)) ...[
            const SizedBox(height: 32),
            Text('맡은 기록', style: AppText.section),
            const SizedBox(height: 14),
            for (final item in data.entrusted)
              if (item.hasAnything) _EntrustedRow(item: item),
          ],
          if (todos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text('마무리할 일', style: AppText.section),
                const Spacer(),
                Text('${todos.length}', style: AppText.greeting),
              ],
            ),
            const SizedBox(height: 8),
            for (final todo in todos) _TodoRow(todo: todo),
          ],
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.name,
    required this.imageUrl,
    required this.onOpenProfile,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = firstCharacter(name);
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greetingFor(DateTime.now()), style: AppText.greeting),
              const SizedBox(height: 2),
              Text('$name님', style: AppText.homeName),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => context.push(Routes.notifications),
              icon: const AppIcon('assets/icons/icon_bell.svg', size: 24),
            ),
            if (unread > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.unread,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: '프로필',
          onPressed: onOpenProfile,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.inkDeep,
            foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
            child: Text(
              initial,
              style: AppText.section.copyWith(
                color: AppColors.white,
                fontSize: 13,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.accountCount,
    required this.assigned,
    required this.total,
    required this.letters,
    required this.people,
    required this.confirmers,
    required this.onOpenData,
    required this.onOpenLetters,
    required this.onOpenPeople,
  });

  final int accountCount;
  final int assigned;
  final int total;
  final int letters;
  final int people;
  final int confirmers;
  final VoidCallback onOpenData;
  final VoidCallback onOpenLetters;
  final VoidCallback onOpenPeople;

  @override
  Widget build(BuildContext context) {
    final missing = total - assigned;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.inkDeep,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '데이터 $accountCount개',
                style: AppText.homeName.copyWith(
                  color: AppColors.white,
                  fontSize: 20,
                  height: 24 / 20,
                ),
              ),
              const Spacer(),
              Text(
                '내 기록 · 생전',
                style: AppText.helper.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: total == 0
                          ? AppColors.barIdle
                          : i <
                                (assigned * 5 / (total == 0 ? 1 : total))
                                    .floor()
                          ? AppColors.sage
                          : AppColors.barIdle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '공개 대상 지정',
                style: AppText.helper.copyWith(
                  color: AppColors.white.withValues(alpha: 0.78),
                  height: 1,
                ),
              ),
              const Spacer(),
              Text(
                '$assigned / $total',
                style: AppText.section.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          if (missing > 0) ...[
            const SizedBox(height: 11),
            InkWell(
              onTap: onOpenData,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '공개 대상 $missing개를 더 지정해 주세요  →',
                  style: AppText.helper.copyWith(
                    color: AppColors.sage,
                    height: 20 / 13,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppColors.white, height: 1, thickness: 0.5),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: '남기는 말',
                  value: '$letters통',
                  hint: letters == 0 ? '없음' : '전달 예정',
                  onTap: onOpenLetters,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: '관계자',
                  value: '$people명',
                  hint: '수락한 확인자 $confirmers',
                  onTap: onOpenPeople,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.helper.copyWith(
                color: AppColors.white.withValues(alpha: 0.78),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: AppText.homeName.copyWith(
                      color: AppColors.white,
                      fontSize: 20,
                      letterSpacing: 0,
                    ),
                  ),
                  TextSpan(
                    text: ' $hint',
                    style: AppText.helper.copyWith(
                      color: AppColors.white.withValues(alpha: 0.78),
                      height: 1,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntrustedRow extends StatelessWidget {
  const _EntrustedRow({required this.item});

  final EntrustedOwner item;

  String get _caption {
    if (item.error != null) return item.error!;
    if (item.tasks.isEmpty) {
      return item.activeCase != null
          ? '사후 전환 확인 중'
          : '남긴 말 ${item.letters.length}통';
    }
    return '맡은 데이터 ${item.tasks.length}개 중 ${item.doneCount}개 완료';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EntrustedOwnerScreen(ownerId: item.owner.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.inkDeep,
              child: Text(
                firstCharacter(item.owner.name),
                style: AppText.section.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.owner.name} 님의 기록', style: AppText.section),
                  const SizedBox(height: 2),
                  Text(_caption, style: AppText.helper.copyWith(height: 1)),
                ],
              ),
            ),
            const AppIcon(
              'assets/icons/icon_chevron_small.svg',
              size: 16,
              color: Color(0xFFB8BEC7),
            ),
          ],
        ),
      ),
    );
  }
}

class _Todo {
  const _Todo({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.todo});

  final _Todo todo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: todo.onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AppIcon(todo.icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                todo.title,
                style: AppText.greeting.copyWith(
                  fontSize: 15,
                  height: 21 / 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(todo.caption, style: AppText.helper.copyWith(height: 1)),
            const SizedBox(width: 8),
            const AppIcon(
              'assets/icons/icon_chevron_right.svg',
              size: 16,
              color: Color(0xFFB8BEC7),
            ),
          ],
        ),
      ),
    );
  }
}

String _ellipsis(String value, int max) {
  final trimmed = value.trim().replaceAll('\n', ' ');
  if (trimmed.runes.length <= max) return trimmed;
  return '${String.fromCharCodes(trimmed.runes.take(max))}…';
}
