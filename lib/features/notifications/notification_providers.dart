import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_notification.dart';
import '../../data/providers.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).list(),
);

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationRepositoryProvider).unreadCount(),
);
