import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/account.dart';

const _descriptions = {
  AccountActionKind.delete: '계정이나 자료를 지워 주세요',
  AccountActionKind.remain: '그대로 두거나 추모 계정으로 남겨 주세요',
  AccountActionKind.backupAndDelete: '필요한 자료를 보관한 뒤 지워 주세요',
  AccountActionKind.permissionMove: '지정한 사람에게 넘겨 주세요 (요청 기록)',
  AccountActionKind.other: '처리 방법을 자유롭게 적어요',
};

const _sheetOrder = [
  AccountActionKind.delete,
  AccountActionKind.remain,
  AccountActionKind.backupAndDelete,
  AccountActionKind.permissionMove,
  AccountActionKind.other,
];

/// Modal sheet for `처리 방식 선택`. Picking an option closes it right away;
/// dismissing keeps the current choice, and the detail text is never cleared.
Future<AccountActionKind?> showActionMethodSheet(
  BuildContext context, {
  AccountActionKind? selected,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<AccountActionKind>(
    context: context,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.inkDeep.withValues(alpha: 0.28),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _ActionMethodSheet(selected: selected),
  );
}

class _ActionMethodSheet extends StatelessWidget {
  const _ActionMethodSheet({this.selected});

  final AccountActionKind? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            child: Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.fieldLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Text(
                    '처리 방식 선택',
                    style: AppText.serviceName.copyWith(
                      color: AppColors.inkDeep,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: AppColors.muted,
                    ),
                    child: Text(
                      '닫기',
                      style: AppText.listCaption.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 21 / 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final kind in _sheetOrder)
                  _Option(
                    kind: kind,
                    selected: kind == selected,
                    onTap: () => Navigator.of(context).pop(kind),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final AccountActionKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: selected ? AppColors.optionSelected : AppColors.white,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.label,
                    style: AppText.rowValue.copyWith(
                      height: 24 / 15,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descriptions[kind]!,
                    style: AppText.listCaption.copyWith(
                      fontSize: 12,
                      height: 19 / 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              const AppIcon('assets/icons/icon_check.svg', size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
