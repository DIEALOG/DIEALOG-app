import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/diealog_logo.png',
              width: 215,
              height: 128,
            ),
            const SizedBox(height: 24),
            Text('D I E A L O G', style: AppText.brand),
          ],
        ),
      ),
    );
  }
}
