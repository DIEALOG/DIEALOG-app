import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../../data/models/account.dart';
import 'legacy_providers.dart';

/// `05 · 내 데이터`: every registered account, grouped by service.
class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(dataOverviewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Text('내 데이터', style: AppText.screenTitle),
              const Spacer(),
              IconButton(
                // 10~13 데이터 등록 플로우는 다음 단계에서 연결합니다.
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데이터 등록 화면은 다음 단계에서 이어집니다.')),
                ),
                tooltip: '데이터 추가',
                icon: const AppIcon('assets/icons/icon_plus.svg', size: 24),
              ),
            ],
          ),
        ),
        Expanded(
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              text: e is ApiException ? e.message : '목록을 불러오지 못했어요.',
            ),
            data: (data) => _Body(
              data: data,
              search: _search,
              query: _query,
              onQuery: (value) => setState(() => _query = value),
              onRefresh: () async => ref.refresh(dataOverviewProvider.future),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.search,
    required this.query,
    required this.onQuery,
    required this.onRefresh,
  });

  final DataOverview data;
  final TextEditingController search;
  final String query;
  final ValueChanged<String> onQuery;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final accounts = data.accounts;
    final services = <String>{for (final a in accounts) a.type?.label ?? '기타'};
    final matching = [
      for (final account in accounts)
        if (_matches(account, query)) account,
    ];

    // Services keep the order they first appear in, like the design.
    final grouped = <String, List<Account>>{};
    for (final account in matching) {
      grouped.putIfAbsent(account.type?.label ?? '기타', () => []).add(account);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const SizedBox(height: 8),
          Text(
            '${services.length}개 서비스 · ${accounts.length}개 항목',
            style: AppText.greeting.copyWith(height: 1),
          ),
          const SizedBox(height: 16),
          _SearchField(controller: search, onChanged: onQuery),
          if (matching.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Text(
                accounts.isEmpty
                    ? '아직 등록한 데이터가 없어요.\n오른쪽 위 + 로 첫 데이터를 등록해 보세요.'
                    : '‘$query’와 맞는 데이터가 없어요.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ),
          for (final entry in grouped.entries) ...[
            _ServiceHeading(name: entry.key),
            for (final account in entry.value)
              _AccountRow(
                account: account,
                audience: audienceOf(account, data.groups).length,
                onTap: () => context.push(
                  Routes.accountDetailOf(data.legacyIdOf(account), account.id),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static bool _matches(Account account, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      account.name,
      account.type?.label ?? '',
      account.accountId ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.search,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const AppIcon('assets/icons/icon_search.svg', size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.navy,
              style: AppText.greeting.copyWith(
                color: AppColors.ink,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 2),
                hintText: '서비스나 계정 검색',
                hintStyle: AppText.greeting.copyWith(
                  color: AppColors.hint,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ServiceHeading extends StatelessWidget {
  const _ServiceHeading({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 17, bottom: 3),
      child: Text(name, style: AppText.serviceName),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.audience,
    required this.onTap,
  });

  final Account account;
  final int audience;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final action = account.action?.label ?? '처리 지침 없음';
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.listDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name.isEmpty ? '이름 없는 항목' : account.name,
                    style: AppText.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$action · '),
                        if (audience > 0)
                          TextSpan(text: '$audience명 열람')
                        else
                          TextSpan(
                            text: '대상 미지정',
                            style: AppText.listCaption.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                      ],
                    ),
                    style: AppText.listCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const AppIcon(
              'assets/icons/icon_chevron_small.svg',
              size: 14,
              color: AppColors.chevron,
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: AppText.body, textAlign: TextAlign.center),
      ),
    );
  }
}
