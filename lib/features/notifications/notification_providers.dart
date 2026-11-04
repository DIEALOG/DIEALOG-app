import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/app_notification.dart';
import '../../data/providers.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final items = await ref.watch(notificationRepositoryProvider).list();
    try {
      await ref.read(entrustedRepositoryProvider).rememberNotifications(items);
    } on ApiException {
      // A profile refresh failure must not hide notifications already loaded.
    }
    return items;
  },
);

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationRepositoryProvider).unreadCount(),
);
