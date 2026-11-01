import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/settings/settings_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/primary_button.dart';

class AppLockHost extends ConsumerStatefulWidget {
  const AppLockHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockHost> createState() => _AppLockHostState();
}

class _AppLockHostState extends ConsumerState<AppLockHost>
    with WidgetsBindingObserver {
  var _locked = false;
  var _busy = false;
  var _leftForeground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftForeground = true;
    }
    if (state == AppLifecycleState.resumed && _leftForeground) {
      _leftForeground = false;
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    if (ref.read(authControllerProvider) != AuthStatus.signedIn) return;
    final settings = ref.read(localSettingsProvider).value;
    if (settings == null || !settings.lockByFaceId) return;
    if (!await ref.read(biometricAuthProvider).canAuthenticate()) return;
    if (mounted) setState(() => _locked = true);
  }

  Future<void> _unlock() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(biometricAuthProvider)
        .authenticate('앱 잠금을 해제하려면 인증해 주세요.');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next != AuthStatus.signedIn && _locked) {
        setState(() => _locked = false);
      }
      if (previous != AuthStatus.signedIn && next == AuthStatus.signedIn) {
        _maybeLock();
      }
    });
    ref.listen(localSettingsProvider, (previous, next) {
      if (next.value?.lockByFaceId == true) _maybeLock();
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_locked) _LockGate(busy: _busy, onUnlock: _unlock),
      ],
    );
  }
}

class _LockGate extends StatelessWidget {
  const _LockGate({required this.busy, required this.onUnlock});

  final bool busy;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.bg,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('앱이 잠겨 있어요', style: AppText.screenTitle),
            const SizedBox(height: 12),
            Text(
              'Face ID 또는 기기 암호로 잠금을 해제해 주세요.',
              style: AppText.body,
            ),
            const Spacer(),
            PrimaryButton(
              label: '잠금 해제',
              busy: busy,
              onPressed: busy ? null : onUnlock,
            ),
          ],
        ),
      ),
    ),
  );
}
