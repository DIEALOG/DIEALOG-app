import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'app_icon.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => context.pop(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: const AppIcon(
        'assets/images/icon_back.svg',
        size: 44,
        color: AppColors.inkDeep,
      ),
    );
  }
}
