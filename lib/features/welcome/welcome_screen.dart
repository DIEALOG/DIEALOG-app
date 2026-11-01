import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/images/diealog_logo.png',
                width: 215,
                height: 128,
              ),
              const SizedBox(height: 49),
              Text('D I E A L O G', style: AppText.brand),
              const Spacer(flex: 4),
              PrimaryButton(
                label: '시작하기',
                height: 48,
                radius: 7,
                textStyle: AppText.startButton,
                onPressed: () => context.push(Routes.signupName),
              ),
              const SizedBox(height: 2),
              TextButton(
                onPressed: () => context.push(Routes.login),
                style: TextButton.styleFrom(
                  minimumSize: const Size(124, 44),
                  foregroundColor: AppColors.inkDeep,
                ),
                child: Text('이미 계정이 있어요', style: AppText.textButton),
              ),
              TextButton(
                onPressed: () => context.push(Routes.invitation),
                child: Text('확인자 초대 코드가 있어요', style: AppText.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
