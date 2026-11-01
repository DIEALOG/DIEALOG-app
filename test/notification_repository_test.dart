import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/app_notification.dart';
import 'package:diealog_app/data/repositories/notification_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists seeded notifications and marks one read', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    final repo = NotificationRepository(dio);

    final items = await repo.list();
    expect(items, isNotEmpty);
    expect(await repo.unreadCount(), greaterThan(0));

    final unread = items.firstWhere((item) => !item.isRead);
    expect(unread.kind, NotificationKind.invite);
    expect(unread.invitationToken, isNotEmpty);

    await repo.markRead(unread.id);
    expect(await repo.unreadCount(), await repo.list().then((list) => list.where((item) => !item.isRead).length));

    await repo.delete(unread.id);
    expect(
      (await repo.list()).any((item) => item.id == unread.id),
      isFalse,
    );
    dio.close();
  });
}
