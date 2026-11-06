import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';

/// Asks why the confirmer is starting a transition case.
///
/// Returns the reason, an empty string when the confirmer skipped it, or null
/// when they backed out. The server keeps the text on the case so the other
/// confirmers see what they are being asked to agree with.
Future<String?> showTransitionReasonSheet(
  BuildContext context,
  String ownerName,
) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
    ),
    child: _ReasonForm(ownerName: ownerName),
  ),
);

class _ReasonForm extends StatefulWidget {
  const _ReasonForm({required this.ownerName});

  final String ownerName;

  @override
  State<_ReasonForm> createState() => _ReasonFormState();
}

class _ReasonFormState extends State<_ReasonForm> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.ownerName}님의 사후 전환 확인 요청', style: AppText.screenTitle),
          const SizedBox(height: 12),
          Text(
            '요청하면 다른 확인자들에게 사실 확인을 묻습니다. '
            '실제 사실을 확인한 뒤 진행해 주세요.',
            style: AppText.paragraph,
          ),
          const SizedBox(height: 20),
          Text('요청 사유 (선택)', style: AppText.fieldLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _reason,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '다른 확인자가 판단할 수 있도록 적어 주세요.',
              filled: true,
              fillColor: AppColors.field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: '요청하기',
            height: 48,
            onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소', style: AppText.textButton),
            ),
          ),
        ],
      ),
    ),
  );
}
