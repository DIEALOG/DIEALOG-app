import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/profile.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';

final _profileProvider = FutureProvider.autoDispose<Profile>(
  (ref) => ref.watch(profileRepositoryProvider).fetch(),
);

/// Placeholder that proves an authenticated call works end to end.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(_profileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: profile.when(
          data: (p) => Text('${p.name} (${p.email})'),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(e is ApiException ? e.message : '$e'),
        ),
      ),
    );
  }
}
