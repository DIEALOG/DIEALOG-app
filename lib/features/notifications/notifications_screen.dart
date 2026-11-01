import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/app_notification.dart';
import '../../data/providers.dart';
import '../settings/confirmers_screen.dart';
import '../transition/confirmer_cases_screen.dart';
import '../transition/invitation_screen.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  var _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              actionLabel: '모두 읽음',
              onAction: items.asData == null ? null : _markAllRead,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('알림', style: AppText.screenTitle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: '전체',
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '읽지 않음',
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(notificationsProvider),
                    child: Text(
                      error is ApiException
                          ? error.message
                          : '알림을 불러오지 못했어요. 다시 시도',
                    ),
                  ),
                ),
                data: (all) {
                  final visible = [
                    for (final item in all)
                      if (!_unreadOnly || !item.isRead) item,
                  ];
                  if (all.isEmpty) {
                    return _Empty(
                      title: '아직 알림이 없어요.',
                      caption: '초대나 확인 요청 등 새 소식이 오면 알려드릴게요.',
                      actionLabel: '홈으로',
                      onAction: () => Navigator.of(context).pop(),
                    );
                  }
                  if (visible.isEmpty) {
                    return const _Empty(
                      title: '읽지 않은 알림이 없어요.',
                      caption: '새 알림이 오면 여기에서 확인할 수 있어요.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        ref.refresh(unreadNotificationCountProvider.future),
                        ref.refresh(notificationsProvider.future),
                      ]);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ConfirmerCasesScreen(),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Text('내가 맡은 역할', style: AppText.section),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppColors.chevron,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        for (final item in visible)
                          _NotificationTile(
                            item: item,
                            onOpen: () => _open(item),
                            onDelete: () => _delete(item),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(item.id);
      } on ApiException {
        // Opening still proceeds; the list refreshes below.
      }
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }
    if (!mounted) return;
    final page = _destination(item);
    if (page != null) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }
  }

  Widget? _destination(AppNotification item) {
    if (item.invitationToken != null) {
      return InvitationScreen(initialToken: item.invitationToken);
    }
    return switch (item.eventType) {
      'confirmer_invitation' => const InvitationScreen(),
      'confirmer_invitation_accepted' ||
      'confirmer_invitation_declined' => const ConfirmersScreen(),
      _ => switch (item.kind) {
        NotificationKind.transition ||
        NotificationKind.invite => const ConfirmerCasesScreen(),
        _ => null,
      },
    };
  }

  Future<void> _markAllRead() async {
    final items = ref.read(notificationsProvider).asData?.value ?? [];
    final repo = ref.read(notificationRepositoryProvider);
    for (final item in items.where((item) => !item.isRead)) {
      try {
        await repo.markRead(item.id);
      } on ApiException {
        break;
      }
    }
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _delete(AppNotification item) async {
    try {
      await ref.read(notificationRepositoryProvider).delete(item.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final AppNotification item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(item.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => onDelete(),
    background: const ColoredBox(
      color: AppColors.unread,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Text('삭제', style: TextStyle(color: AppColors.white)),
        ),
      ),
    ),
    child: InkWell(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        decoration: BoxDecoration(
          color: item.isRead ? null : AppColors.optionSelected,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: AppText.listTitle),
            const SizedBox(height: 4),
            Text(item.message, style: AppText.paragraph),
            const SizedBox(height: 4),
            Text(item.caption, style: AppText.listCaption),
            const SizedBox(height: 8),
            Text(item.timeLabel, style: AppText.footnote),
          ],
        ),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.inkDeep : AppColors.field,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppText.listCaption.copyWith(
          color: selected ? AppColors.white : AppColors.ink,
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.caption,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String caption;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppText.section, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(caption, style: AppText.body, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
