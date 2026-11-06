import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/confirmer_access.dart';
import '../../data/models/transition_case.dart';
import '../../data/providers.dart';
import '../notifications/notification_providers.dart';
import 'confirmer_cases_screen.dart';
import 'transition_reason_sheet.dart';

class TransitionRequestOwner {
  const TransitionRequestOwner(this.session, this.name, this.activeCase);

  final ConfirmerSession session;
  final String name;
  final TransitionCase? activeCase;
}

final transitionRequestOwnersProvider =
    FutureProvider.autoDispose<List<TransitionRequestOwner>>((ref) async {
      final entries = await ref.watch(confirmerInboxProvider.future);
      final owners = await ref.watch(designatingUsersProvider.future);
      final notices = await ref.watch(notificationsProvider.future);
      final repository = ref.watch(confirmerRepositoryProvider);
      final confirmedOwnerIds = {
        for (final notice in notices)
          if (notice.eventType == 'transition_confirmed')
            '${notice.metadata['target_user_id'] ?? ''}',
      };
      final result = <TransitionRequestOwner>[];
      for (final entry in entries) {
        final alreadyConfirmed = entry.cases.any(
          (item) => item.status == TransitionCaseStatus.confirmed,
        );
        if (entry.error != null ||
            alreadyConfirmed ||
            confirmedOwnerIds.contains(entry.session.ownerUserId)) {
          continue;
        }
        // The list endpoint returns active cases only. Check cases already seen
        // on this device so a confirmed owner cannot be requested again.
        var confirmed = false;
        for (final caseId in entry.session.knownCaseIds) {
          try {
            final item = await repository.getCase(entry.session.authToken, caseId);
            if (item.status == TransitionCaseStatus.confirmed) {
              confirmed = true;
              break;
            }
          } on ApiException {
            // When history cannot be verified, do not offer a new request.
            confirmed = true;
            break;
          }
        }
        if (confirmed) continue;
        final name = owners
            .where((owner) => owner.id == entry.session.ownerUserId)
            .map((owner) => owner.name)
            .where((name) => name.isNotEmpty)
            .firstOrNull;
        final open = entry.cases
            .where(
              (item) =>
                  item.status == TransitionCaseStatus.pendingConfirmation ||
                  item.status == TransitionCaseStatus.waitingPeriod,
            )
            .firstOrNull;
        result.add(
          TransitionRequestOwner(entry.session, name ?? '소유자', open),
        );
      }
      return result;
    });

class TransitionRequestScreen extends ConsumerWidget {
  const TransitionRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owners = ref.watch(transitionRequestOwnersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('사후 전환 요청하기'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(confirmerInboxProvider);
          ref.invalidate(designatingUsersProvider);
          ref.invalidate(notificationsProvider);
          return ref.refresh(transitionRequestOwnersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text('사후 전환 요청하기', style: AppText.screenTitle),
            const SizedBox(height: 12),
            Text('확인자로 지정된 사람', style: AppText.section),
            owners.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => TextButton(
                onPressed: () => ref.invalidate(transitionRequestOwnersProvider),
                child: Text(error is ApiException
                    ? error.userMessage
                    : '목록을 불러오지 못했어요. 다시 시도'),
              ),
              data: (people) => people.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text('요청할 수 있는 사람이 없어요.', style: AppText.body),
                    )
                  : Column(
                      children: [
                        for (final person in people)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(person.name, style: AppText.listTitle),
                            subtitle: Text(
                              person.activeCase == null
                                  ? '사후 전환 확인 요청하기'
                                  : '진행 중인 요청이 있어요',
                              style: AppText.listCaption,
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.chevron),
                            onTap: () => person.activeCase == null
                                ? _startCase(context, ref, person)
                                : _openCase(context, ref, person,
                                    person.activeCase!),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCase(BuildContext context, WidgetRef ref,
      TransitionRequestOwner person, TransitionCase item) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ConfirmerCaseDetailScreen(
        session: person.session,
        caseId: item.id,
        initialCase: item,
        ownerName: person.name,
      ),
    ));
    ref.invalidate(confirmerInboxProvider);
    ref.invalidate(transitionRequestOwnersProvider);
  }

  Future<void> _startCase(BuildContext context, WidgetRef ref,
      TransitionRequestOwner person) async {
    final reason = await showTransitionReasonSheet(context, person.name);
    if (reason == null || !context.mounted) return;
    try {
      final item = await ref
          .read(confirmerRepositoryProvider)
          .startCase(person.session.authToken, reason: reason);
      await ref.read(confirmerSessionStoreProvider).upsert(
            person.session.withCaseIds([item.id]),
          );
      ref.invalidate(confirmerInboxProvider);
      ref.invalidate(transitionRequestOwnersProvider);
      if (context.mounted) await _openCase(context, ref, person, item);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
      }
      ref.invalidate(confirmerInboxProvider);
      ref.invalidate(transitionRequestOwnersProvider);
    }
  }
}
