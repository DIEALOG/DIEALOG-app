import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/stakeholder.dart';
import '../../data/models/transition_confirmer.dart';
import '../../data/providers.dart';
import '../legacy/legacy_providers.dart';

class PeopleOverview {
  const PeopleOverview({required this.data, required this.confirmers});

  final DataOverview data;
  final List<TransitionConfirmer> confirmers;

  List<Stakeholder> get people => data.people.values.toList();
  List<StakeholderGroup> get groups => data.groups.values.toList();
  List<TransitionConfirmer> get activeConfirmers =>
      confirmers.where((item) => item.isActive).toList();

  int accountCountFor(String personId) => data.accounts
      .where((account) => audienceOf(account, data.groups).contains(personId))
      .length;

  int accountCountForGroup(String groupId) => data.accounts
      .where((account) => account.stakeholderGroupIds.contains(groupId))
      .length;

  List<Stakeholder> membersOf(StakeholderGroup group) => [
    for (final id in group.stakeholderIds) ?data.people[id],
  ];

  TransitionConfirmer? confirmerFor(String personId) {
    for (final item in activeConfirmers) {
      if (item.stakeholderId == personId) return item;
    }
    return null;
  }
}

final peopleOverviewProvider = FutureProvider.autoDispose<PeopleOverview>((
  ref,
) async {
  final data = await ref.watch(dataOverviewProvider.future);
  final confirmers = await ref
      .watch(transitionRepositoryProvider)
      .listConfirmers();
  return PeopleOverview(data: data, confirmers: confirmers);
});
