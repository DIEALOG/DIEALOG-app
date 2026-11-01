import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import 'incoming_link.dart';

class IncomingLinkBinder extends ConsumerStatefulWidget {
  const IncomingLinkBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingLinkBinder> createState() => _IncomingLinkBinderState();
}

class _IncomingLinkBinderState extends ConsumerState<IncomingLinkBinder> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    try {
      final links = AppLinks();
      final initial = await links.getInitialLink();
      if (initial != null) _open(initial);
      _subscription = links.uriLinkStream.listen(_open);
    } catch (_) {
      // Plugin is absent in tests and some desktop builds.
    }
  }

  void _open(Uri uri) {
    final location = IncomingLink.locationOf(uri);
    if (location == null) return;
    ref.read(routerProvider).go(location);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
