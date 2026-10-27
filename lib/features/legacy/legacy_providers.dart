import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/account.dart';
import '../../data/models/legacy.dart';
import '../../data/models/stakeholder.dart';
import '../../data/providers.dart';

/// Everything the 데이터 tab needs in one load.
///
/// List responses carry only the ids of the stakeholders and groups an account
/// is disclosed to, so both are fetched alongside to resolve names and counts.
class DataOverview {
  const DataOverview({
    required this.legacies,
    required this.groups,
    required this.people,
  });

  final List<Legacy> legacies;
  final Map<String, StakeholderGroup> groups;
  final Map<String, Stakeholder> people;

  List<Account> get accounts => [
        for (final legacy in legacies) ...legacy.accounts,
      ];

  /// The legacy an account belongs to, used when opening its detail route.
  String legacyIdOf(Account account) =>
      account.legacyId ??
      legacies
          .firstWhere(
            (l) => l.accounts.any((a) => a.id == account.id),
            orElse: () => legacies.first,
          )
          .id;

  Account? accountById(String id) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  /// Fills a list-shaped account's stakeholders and groups from their ids, so
  /// it can be shown without the credential-bearing detail response.
  Account resolve(Account account) => Account(
        id: account.id,
        legacyId: account.legacyId,
        name: account.name,
        type: account.type,
        action: account.action,
        accountId: account.accountId,
        accountPassword: account.accountPassword,
        dataLocation: account.dataLocation,
        stakeholderIds: account.stakeholderIds,
        stakeholders: [
          for (final id in account.stakeholderIds) ?people[id],
        ],
        stakeholderGroupIds: account.stakeholderGroupIds,
        stakeholderGroups: [
          for (final id in account.stakeholderGroupIds) ?groups[id],
        ],
        createdAt: account.createdAt,
      );
}

final dataOverviewProvider = FutureProvider.autoDispose<DataOverview>((ref) async {
  final legacies = await ref.watch(legacyRepositoryProvider).list();
  final stakeholders = ref.watch(stakeholderRepositoryProvider);
  final groups = await stakeholders.listGroups();
  final people = await stakeholders.list();
  return DataOverview(
    legacies: legacies,
    groups: {for (final group in groups) group.id: group},
    people: {for (final person in people) person.id: person},
  );
});

typedef AccountKey = ({String legacyId, String accountId});

/// Detail shape: stakeholders, groups with members, and the password.
final accountProvider =
    FutureProvider.autoDispose.family<Account, AccountKey>((ref, key) {
  return ref.watch(legacyRepositoryProvider).getAccount(
        key.legacyId,
        key.accountId,
      );
});

/// What the detail screen shows: the account itself, plus whether the
/// credential-bearing detail call came back.
///
/// Reading an account's credentials goes through the server's crypto service.
/// When that call fails the rest of the screen still renders from the list
/// data, and [credentialError] explains the missing 계정 정보 section.
class AccountDetail {
  const AccountDetail({required this.account, this.credentialError});

  final Account account;
  final String? credentialError;

  bool get hasCredentials => credentialError == null;
}

final accountDetailProvider =
    FutureProvider.autoDispose.family<AccountDetail, AccountKey>((ref, key) async {
  final legacies = ref.watch(legacyRepositoryProvider);
  final overview = await ref.watch(dataOverviewProvider.future);
  try {
    return AccountDetail(
      account: await legacies.getAccount(key.legacyId, key.accountId),
    );
  } on ApiException catch (e) {
    final listed = overview.accountById(key.accountId);
    if (listed == null) rethrow;
    return AccountDetail(
      account: overview.resolve(listed),
      credentialError: e.message,
    );
  }
});

/// Everyone who gets to see [account] after death, counting each person once.
Set<String> audienceOf(Account account, Map<String, StakeholderGroup> groups) {
  final ids = <String>{
    ...account.stakeholderIds,
    for (final s in account.stakeholders) s.id,
  };
  for (final groupId in account.stakeholderGroupIds) {
    final group = groups[groupId];
    if (group != null) ids.addAll(group.stakeholderIds);
  }
  for (final group in account.stakeholderGroups) {
    ids
      ..addAll(group.stakeholderIds)
      ..addAll([for (final s in group.stakeholders) s.id]);
  }
  return ids..removeWhere((id) => id.isEmpty);
}
