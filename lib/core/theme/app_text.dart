import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppText {
  static const family = 'Pretendard';

  static TextStyle get brand => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        fontSize: 30,
        height: 31.9 / 30,
        letterSpacing: -0.0147 * 30,
        color: AppColors.ink,
      );

  static TextStyle get authTitle => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 38 / 26,
        color: AppColors.ink,
      );

  static TextStyle get stepTitle => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 38 / 26,
        color: AppColors.ink,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 24 / 14,
        color: AppColors.caption,
      );

  static TextStyle get fieldLabel => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        height: 20 / 13,
        color: AppColors.label,
      );

  static TextStyle get fieldValue => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 19,
        height: 28 / 19,
        color: AppColors.ink,
      );

  static TextStyle get helper => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 13,
        height: 22 / 13,
        color: AppColors.caption,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 26 / 16,
        color: AppColors.white,
      );

  static TextStyle get startButton => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.white,
      );

  static TextStyle get textButton => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: AppColors.inkDeep,
      );

  static TextStyle get link => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 22 / 14,
        color: AppColors.muted,
      );

  static TextStyle get footnote => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 11,
        height: 18 / 11,
        color: AppColors.hint,
      );

  static TextStyle get stepIndex => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        height: 24 / 13,
        color: AppColors.caption,
      );

  static TextStyle get greeting => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: -0.0114 * 14,
        color: AppColors.muted,
      );

  static TextStyle get homeName => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.02 * 22,
        color: AppColors.ink,
      );

  static TextStyle get section => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: -0.0107 * 15,
        color: AppColors.ink,
      );

  static TextStyle get tab => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 11,
      );

  static TextStyle get otpDigit => const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w500,
        fontSize: 22,
        height: 35 / 22,
        color: AppColors.inkDeep,
      );
}
