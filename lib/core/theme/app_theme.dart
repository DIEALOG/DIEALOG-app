import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        surface: AppColors.bg,
        onSurface: AppColors.ink,
        secondary: AppColors.inkDeep,
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.inkDeep,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: AppText.family,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
