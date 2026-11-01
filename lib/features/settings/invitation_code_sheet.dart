import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/transition_confirmer.dart';

/// The backend returns the code once and does not deliver email or SMS.
Future<void> showInvitationCodeSheet(
  BuildContext context,
  TransitionInvitation invitation,
) => showModalBottomSheet<void>(
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
          Text('확인자 초대 코드', style: AppText.screenTitle),
          const SizedBox(height: 12),
          Text(
            '${invitation.confirmer.name} 님에게 아래 코드를 전달해 주세요. '
            '현재 서버는 이메일이나 문자를 자동 발송하지 않습니다.',
            style: AppText.paragraph,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              invitation.token,
              style: AppText.body.copyWith(color: AppColors.ink, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '유효기간: ${invitation.expiresAt.toLocal().year}년 '
            '${invitation.expiresAt.toLocal().month}월 '
            '${invitation.expiresAt.toLocal().day}일까지',
            style: AppText.helper,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: '코드 복사',
            height: 48,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invitation.token));
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('초대 코드를 복사했어요. 직접 전달해 주세요.')),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text('닫기', style: AppText.textButton),
            ),
          ),
          Text(
            '이 화면을 닫으면 코드를 다시 볼 수 없습니다. '
            '필요하면 새 코드를 발급해 주세요.',
            style: AppText.footnote,
          ),
        ],
      ),
    ),
  ),
);
