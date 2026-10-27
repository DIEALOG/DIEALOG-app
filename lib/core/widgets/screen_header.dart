import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'app_back_button.dart';

/// Back button on the left and an optional text action on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    this.onBack,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final VoidCallback? onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Replaces the text action when a richer widget is needed.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 6),
          AppBackButton(onPressed: onBack),
          const Spacer(),
          if (trailing != null)
            trailing!
          else if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppText.headerAction.color,
              ),
              child: Text(actionLabel!, style: AppText.headerAction),
            )
          else
            const SizedBox(width: 50),
        ],
      ),
    );
  }
}
