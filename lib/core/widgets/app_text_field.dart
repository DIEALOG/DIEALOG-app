import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final Widget? helper;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.fieldLabel),
        const SizedBox(height: 9),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: focused ? AppColors.navy : AppColors.fieldLine,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: AppColors.navy,
            style: AppText.fieldValue,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: widget.hint,
              hintStyle: AppText.fieldValue.copyWith(color: AppColors.hint),
            ),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 14),
          widget.helper!,
        ],
      ],
    );
  }
}
