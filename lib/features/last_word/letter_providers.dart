import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/last_word.dart';
import '../../data/models/stakeholder.dart';
import '../../data/providers.dart';
import 'letter_draft_store.dart';

class LetterOverview {
  const LetterOverview({
    required this.userId,
    required this.letters,
    required this.people,
    required this.groups,
    this.newDraft,
  });

  final String userId;
  final List<LastWord> letters;
  final List<Stakeholder> people;
  final List<StakeholderGroup> groups;
  final LetterDraft? newDraft;

  String recipientLabel(LastWord letter) {
    final groupsById = {for (final group in groups) group.id: group};
    final peopleById = {for (final person in people) person.id: person};
    if (letter.receiverGroupIds.length == 1 && letter.receiverIds.isEmpty) {
      return groupsById[letter.receiverGroupIds.single]?.name ??
          letter.receiverGroups.firstOrNull?.name ??
          '그룹';
    }
    final ids = <String>{...letter.receiverIds};
    for (final groupId in letter.receiverGroupIds) {
      ids.addAll(groupsById[groupId]?.stakeholderIds ?? const []);
    }
    if (ids.isEmpty) return '받는 사람 미지정';
    final first =
        peopleById[ids.first]?.name ??
        letter.receivers.firstOrNull?.name ??
        '관계자';
    return ids.length == 1 ? first : '$first 외 ${ids.length - 1}명';
  }
}

final letterOverviewProvider = FutureProvider.autoDispose<LetterOverview>((
  ref,
) async {
  final profile = await ref.watch(profileRepositoryProvider).fetch();
  final repo = ref.watch(stakeholderRepositoryProvider);
  final groups = await repo.listGroups();
  final people = await repo.list();
  final letters = await ref.watch(lastWordRepositoryProvider).list();
  final newDraft = await ref
      .watch(letterDraftStoreProvider)
      .read(profile.id, 'new');
  return LetterOverview(
    userId: profile.id,
    letters: letters,
    people: people,
    groups: groups,
    newDraft: newDraft,
  );
});

final letterDraftStoreProvider = Provider<LetterDraftStore>(
  (ref) => const SecureLetterDraftStore(FlutterSecureStorage()),
);
