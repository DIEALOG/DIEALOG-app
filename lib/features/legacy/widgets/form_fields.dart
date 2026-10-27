import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_icon.dart';

/// Small bold label above a field, with a muted `선택` for optional ones.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    if (!optional) return Text(label, style: AppText.formLabel);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: '선택',
            style: AppText.formLabel.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
      style: AppText.formLabel,
    );
  }
}

/// 46px single-line input used across the registration steps.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.optional = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool optional;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          FieldLabel(label!, optional: optional),
          const SizedBox(height: 8),
        ],
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.inputLine),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            cursorColor: AppColors.navy,
            style: AppText.rowValue.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: AppText.rowValue.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: AppColors.hint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 46px field that opens a bottom sheet instead of the keyboard.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.onTap,
    this.label,
    this.value,
    this.placeholder = '선택해 주세요',
  });

  final VoidCallback onTap;
  final String? label;
  final String? value;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          FieldLabel(label!),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.inkDeep),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filled ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowValue.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 24 / 15,
                      letterSpacing: 0,
                      color: filled ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
                const AppIcon('assets/icons/icon_chevron_down.svg', size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 22px rounded checkbox from the 공개 대상 선택 screen.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? AppColors.inkDeep : null,
        borderRadius: BorderRadius.circular(6),
        border: checked ? null : Border.all(color: const Color(0xFFC9CED6)),
      ),
      child: checked
          ? const AppIcon('assets/icons/icon_check_small.svg', size: 12)
          : null,
    );
  }
}
