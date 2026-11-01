import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/links/incoming_link_binder.dart';
import 'core/lock/app_lock_host.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DiealogApp()));
}

class DiealogApp extends ConsumerWidget {
  const DiealogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IncomingLinkBinder(
      child: MaterialApp.router(
        title: 'DIEALOG',
        theme: AppTheme.light(),
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) =>
            AppLockHost(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
