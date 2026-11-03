import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/account_handling_task.dart';
import '../transition/stakeholder_task_result_screen.dart';

/// Shows the handling codes `POST .../tasks/{id}/request` just returned.
///
/// The server returns them once and sends no email or SMS, so this is the only
/// chance to copy them. One code is issued per assignee on the account.
Future<void> showHandlingCodeSheet(
  BuildContext context,
  List<AccountHandlingRequest> requests, {
  VoidCallback? onSubmitted,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (sheetContext) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('계정 처리 코드', style: AppText.screenTitle),
          const SizedBox(height: 12),
          Text(
            requests.length == 1
                ? '아래 코드로 처리 결과를 보고할 수 있어요.'
                : '현재 로그인 계정에 연결된 ${requests.length}개의 코드예요. '
                      '처리할 항목의 코드만 사용해 주세요.',
            style: AppText.paragraph,
          ),
          const SizedBox(height: 20),
          for (final request in requests) ...[
            Text(request.name, style: AppText.listTitle),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.field,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                request.token,
                style: AppText.body.copyWith(
                  color: AppColors.ink,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '유효기간 ${request.expiresAt.toLocal().month}월 '
                    '${request.expiresAt.toLocal().day}일까지',
                    style: AppText.helper,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: request.token));
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('처리 코드를 복사했어요.')),
                      );
                    }
                  },
                  child: Text('복사', style: AppText.link),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          PrimaryButton(
            label: '처리 결과 보고하기',
            height: 48,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StakeholderTaskResultScreen(
                    initialToken: requests.length == 1
                        ? requests.single.token
                        : null,
                    onSubmitted: onSubmitted,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text('나중에', style: AppText.textButton),
            ),
          ),
          Text(
            '이 화면을 닫으면 코드를 다시 볼 수 없어요. 필요하면 다시 발급하면 됩니다.',
            style: AppText.footnote,
          ),
        ],
      ),
    ),
  ),
);
