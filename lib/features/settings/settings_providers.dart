import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_prefs.dart';
import '../../data/models/profile.dart';
import '../../data/models/stakeholder.dart';
import '../../data/models/transition_confirmer.dart';
import '../../data/models/transition_policy.dart';
import '../../data/providers.dart';

/// Just the profile, for the 프로필 screen.
final settingsProfileProvider = FutureProvider.autoDispose<Profile>(
  (ref) => ref.watch(profileRepositoryProvider).fetch(),
);

/// Everything the 설정 root needs in one load.
class SettingsOverview {
  const SettingsOverview({
    required this.profile,
    required this.policy,
    required this.confirmers,
  });

  final Profile profile;
  final TransitionPolicy policy;
  final List<TransitionConfirmer> confirmers;

  /// Only accepted confirmers count toward the minimum; invites still
  /// pending do not.
  int get acceptedCount =>
      confirmers.where((c) => c.status == ConfirmerStatus.accepted).length;
}

final settingsOverviewProvider = FutureProvider.autoDispose<SettingsOverview>((
  ref,
) async {
  final profile = await ref.watch(profileRepositoryProvider).fetch();
  final transition = ref.watch(transitionRepositoryProvider);
  final policy = await transition.fetchPolicy();
  final confirmers = await transition.listConfirmers();
  return SettingsOverview(
    profile: profile,
    policy: policy,
    confirmers: confirmers,
  );
});

/// Confirmers plus the stakeholders they can be picked from (19-1, 19-2).
class ConfirmerBoard {
  const ConfirmerBoard({
    required this.confirmers,
    required this.people,
    required this.policy,
  });

  final List<TransitionConfirmer> confirmers;
  final List<Stakeholder> people;
  final TransitionPolicy policy;

  List<TransitionConfirmer> get active =>
      confirmers.where((c) => c.isActive).toList();

  int get acceptedCount =>
      confirmers.where((c) => c.status == ConfirmerStatus.accepted).length;

  /// Revoking an accepted confirmer must not drop the count below the policy
  /// minimum; pending invites cannot take their place yet.
  bool canRevoke(TransitionConfirmer confirmer) =>
      confirmer.status != ConfirmerStatus.accepted ||
      acceptedCount > policy.minimumConfirmers;

  Stakeholder? personFor(TransitionConfirmer confirmer) {
    for (final person in people) {
      if (person.id == confirmer.stakeholderId) return person;
    }
    return null;
  }

  bool isAssigned(Stakeholder person) =>
      active.any((c) => c.stakeholderId == person.id);
}

final confirmerBoardProvider = FutureProvider.autoDispose<ConfirmerBoard>((
  ref,
) async {
  final transition = ref.watch(transitionRepositoryProvider);
  final confirmers = await transition.listConfirmers();
  final policy = await transition.fetchPolicy();
  final people = await ref.watch(stakeholderRepositoryProvider).list();
  return ConfirmerBoard(
    confirmers: confirmers,
    people: people,
    policy: policy,
  );
});

final localSettingsProvider =
    AsyncNotifierProvider<LocalSettingsController, LocalSettings>(
      LocalSettingsController.new,
    );

class LocalSettingsController extends AsyncNotifier<LocalSettings> {
  @override
  Future<LocalSettings> build() =>
      ref.watch(localSettingsStoreProvider).read();

  /// Saves on the device first so the switch stays put, then mirrors the
  /// security pair to the server. A failed sync surfaces as an error without
  /// reverting the local value.
  Future<void> save(LocalSettings next) async {
    state = AsyncData(next);
    await ref.read(localSettingsStoreProvider).write(next);
  }

  Future<void> saveSecurity(LocalSettings next) async {
    await save(next);
    await ref
        .read(profileRepositoryProvider)
        .updateConfig(
          UserConfig(
            lockByFaceId: next.lockByFaceId,
            certificationBeforeSensitiveInformation:
                next.certifyBeforeSensitive,
          ),
        );
  }
}
