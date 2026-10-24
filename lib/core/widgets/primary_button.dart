import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
    this.height = 56,
    this.radius = 10,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool enabled;
  final double height;
  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy && onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: active ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.38),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: textStyle ?? AppText.button,
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                ),
              )
            : Text(label, style: textStyle ?? AppText.button),
      ),
    );
  }
}
