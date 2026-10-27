import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import 'legacy_providers.dart';
import 'widgets/account_sections.dart';

/// `06 · 데이터 상세`
class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({
    super.key,
    required this.legacyId,
    required this.accountId,
  });

  final String legacyId;
  final String accountId;

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  late String _accountId = widget.accountId;

  AccountKey get _key => (legacyId: widget.legacyId, accountId: _accountId);

  /// Editing recreates the account, so the screen follows the new id.
  Future<void> _edit() async {
    final replacement = await context.push<String>(
      Routes.accountEditOf(widget.legacyId, _accountId),
    );
    if (!mounted || replacement == null) return;
    setState(() => _accountId = replacement);
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountDetailProvider(_key));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              actionLabel: '수정',
              // Editing recreates the account, so it needs the credentials.
              onAction: account.value?.hasCredentials ?? false
                  ? _edit
                  : null,
            ),
            Expanded(
              child: account.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e is ApiException ? e.message : '데이터를 불러오지 못했어요.',
                      style: AppText.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (data) => _Body(detail: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final AccountDetail detail;

  @override
  Widget build(BuildContext context) {
    final account = detail.account;
    final message = account.action?.message;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        Text(
          account.type?.label ?? '기타',
          style: AppText.rowValue.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: 3),
        Text(account.name, style: AppText.screenTitle),
        const SizedBox(height: 23),
        Text('처리 지침', style: AppText.listCaption.copyWith(letterSpacing: -0.16)),
        const SizedBox(height: 4),
        Text(
          account.action?.kind.label ?? '지정 안 함',
          style: AppText.listTitle.copyWith(letterSpacing: -0.16),
        ),
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(message, style: AppText.paragraph),
        ],
        const SizedBox(height: 32),
        AccountAudienceSection(account: account),
        const SizedBox(height: 32),
        AccountInfoSection(
          account: account,
          error: detail.credentialError,
        ),
      ],
    );
  }
}
