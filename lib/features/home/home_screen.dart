import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../../data/models/last_word.dart';
import '../../data/models/legacy.dart';
import '../../data/models/profile.dart';
import '../../data/models/stakeholder.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/afterlife_repository.dart';
import 'greeting.dart';

class HomeSnapshot {
  const HomeSnapshot({
    required this.profile,
    required this.legacies,
    required this.stakeholders,
    required this.lastWords,
    required this.entrusted,
  });

  final Profile profile;
  final List<Legacy> legacies;
  final List<Stakeholder> stakeholders;
  final List<LastWord> lastWords;
  final List<EntrustedRecord> entrusted;
}

final homeSnapshotProvider = FutureProvider.autoDispose<HomeSnapshot>((ref) async {
  final profile = await ref.watch(profileRepositoryProvider).fetch();
  final legacies = await ref.watch(legacyRepositoryProvider).list();
  final people = await ref.watch(stakeholderRepositoryProvider).list();
  final lastWords = await ref.watch(lastWordRepositoryProvider).list();
  final entrusted = await ref.watch(afterlifeRepositoryProvider).listEntrusted();
  return HomeSnapshot(
    profile: profile,
    legacies: legacies,
    stakeholders: people,
    lastWords: lastWords,
    entrusted: entrusted,
  );
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(homeSnapshotProvider);
    return snap.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(e is ApiException ? e.message : '$e'),
        ),
      ),
      data: (data) => _HomeBody(data: data),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final HomeSnapshot data;

  @override
  Widget build(BuildContext context) {
    final accounts = data.legacies.expand((l) => l.accounts).toList();
    final assigned = accounts.where((a) => a.hasAudience).length;
    final unassigned = accounts.where((a) => !a.hasAudience).toList();
    final letters = data.lastWords.length;
    final unaddressed = [
      for (final word in data.lastWords)
        if (word.receiverIds.isEmpty && word.receiverGroupIds.isEmpty) word,
    ];
    final confirmers = data.stakeholders.where((s) => s.email != null).length;
    final todos = <_Todo>[
      if (unassigned.isNotEmpty)
        _Todo(
          icon: 'assets/icons/icon_list_data.svg',
          title: unassigned.length == 1
              ? unassigned.single.name
              : '공개 대상 미지정 데이터',
          caption: '공개 대상 미지정',
        ),
      if (data.stakeholders.any((s) => s.email == null && s.phone == null))
        _Todo(
          icon: 'assets/icons/icon_list_people.svg',
          title: '${data.stakeholders.firstWhere((s) => s.email == null && s.phone == null).name} 님',
          caption: '초대 수락 대기',
        ),
      if (unaddressed.isNotEmpty)
        _Todo(
          icon: 'assets/icons/icon_list_letters.svg',
          title: '‘${_ellipsis(unaddressed.first.title, 12)}’',
          caption: '받는 사람 미지정',
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _Header(name: data.profile.name),
        const SizedBox(height: 24),
        _SummaryCard(
          accountCount: accounts.length,
          assigned: assigned,
          total: accounts.length,
          letters: letters,
          people: data.stakeholders.length,
          confirmers: confirmers,
        ),
        if (data.entrusted.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('맡은 기록', style: AppText.section),
          const SizedBox(height: 14),
          for (final record in data.entrusted) _EntrustedRow(record: record),
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = firstCharacter(name);
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
              onPressed: () {},
              icon: const AppIcon('assets/icons/icon_bell.svg', size: 24),
            ),
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
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.inkDeep,
          child: Text(
            initial,
            style: AppText.section.copyWith(
              color: AppColors.white,
              fontSize: 13,
              letterSpacing: 0,
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
  });

  final int accountCount;
  final int assigned;
  final int total;
  final int letters;
  final int people;
  final int confirmers;

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
                          : i < (assigned * 5 / (total == 0 ? 1 : total)).floor()
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
            Text(
              '공개 대상 $missing개를 더 지정해 주세요  →',
              style: AppText.helper.copyWith(color: AppColors.sage, height: 20 / 13),
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
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: '관계자',
                  value: '$people명',
                  hint: '확인자 $confirmers',
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
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class _EntrustedRow extends StatelessWidget {
  const _EntrustedRow({required this.record});

  final EntrustedRecord record;

  @override
  Widget build(BuildContext context) {
    final done = record.status == EntrustedRecordStatus.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.inkDeep,
            child: Text(
              firstCharacter(record.ownerName),
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
                Text('${record.ownerName} 님의 기록', style: AppText.section),
                const SizedBox(height: 2),
                Text(
                  done ? '사후 공개됨 · 처리 완료' : '사후 공개됨 · 처리 필요',
                  style: AppText.helper.copyWith(height: 1),
                ),
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
    );
  }
}

class _Todo {
  const _Todo({required this.icon, required this.title, required this.caption});

  final String icon;
  final String title;
  final String caption;
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.todo});

  final _Todo todo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          AppIcon(todo.icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(todo.title, style: AppText.greeting.copyWith(fontSize: 15, height: 21 / 15, color: AppColors.ink)),
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
    );
  }
}

String _ellipsis(String value, int max) {
  final trimmed = value.trim().replaceAll('\n', ' ');
  if (trimmed.runes.length <= max) return trimmed;
  return '${String.fromCharCodes(trimmed.runes.take(max))}…';
}
