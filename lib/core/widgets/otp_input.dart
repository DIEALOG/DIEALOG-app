import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final FocusNode _focus = FocusNode()..addListener(_refresh);

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  String get _digits {
    final raw = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    return raw.length <= widget.length ? raw : raw.substring(0, widget.length);
  }

  void _onChanged(String value) {
    final next = value.replaceAll(RegExp(r'\D'), '');
    final clipped =
        next.length <= widget.length ? next : next.substring(0, widget.length);
    if (clipped != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
    }
    widget.onChanged?.call(clipped);
    if (clipped.length == widget.length) widget.onCompleted?.call(clipped);
  }

  @override
  Widget build(BuildContext context) {
    final digits = _digits;
    final active = widget.enabled && _focus.hasFocus
        ? digits.length.clamp(0, widget.length - 1)
        : -1;
    return GestureDetector(
      onTap: widget.enabled
          ? () => FocusScope.of(context).requestFocus(_focus)
          : null,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                Expanded(
                  child: _OtpSlot(
                    digit: i < digits.length ? digits[i] : null,
                    focused: i == active,
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofillHints: const [AutofillHints.oneTimeCode],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: _onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpSlot extends StatelessWidget {
  const _OtpSlot({required this.digit, required this.focused});

  final String? digit;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: focused ? AppColors.white : AppColors.field,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: focused ? AppColors.inkDeep : AppColors.fieldLine,
          width: focused ? 2 : 1.5,
        ),
      ),
      child: digit == null
          ? (focused
              ? Container(width: 2, height: 24, color: AppColors.inkDeep)
              : const SizedBox.shrink())
          : Text(digit!, style: AppText.otpDigit),
    );
  }
}
