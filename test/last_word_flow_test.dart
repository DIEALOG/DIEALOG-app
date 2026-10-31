import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/last_word.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/repositories/last_word_repository.dart';
import 'package:diealog_app/features/last_word/letter_draft_store.dart';
import 'package:diealog_app/features/shared/audience_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('group and individual selection counts each recipient once', () {
    const group = StakeholderGroup(
      id: 'family',
      name: '가족',
      stakeholderIds: ['one', 'two'],
    );
    final selected = const AudienceSelection(people: {'one'})
        .toggleGroup(group, [group]);
    expect(selected.resolvedIds([group]), {'one', 'two'});
    expect(selected.groups, {'family'});

    final partial = selected.togglePerson('one', [group]);
    expect(partial.resolvedIds([group]), {'two'});
    expect(partial.groups, isEmpty);
    expect(partial.people, {'two'});
  });

  test('draft preserves title, recipients, and save time', () {
    final draft = LetterDraft(
      title: '안녕',
      message: '고마워',
      receiverIds: const ['one'],
      receiverGroupIds: const ['family'],
      savedAt: DateTime.utc(2026, 10, 30),
    );
    final parsed = LetterDraft.fromJson(draft.toJson());
    expect(parsed.title, draft.title);
    expect(parsed.receiverIds, ['one']);
    expect(parsed.receiverGroupIds, ['family']);
    expect(parsed.savedAt, draft.savedAt);
  });

  test(
    'creates, updates and deletes a letter through the repository',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..interceptors.add(
          MockApiInterceptor(
            backend: MockBackend.seeded(),
            latency: Duration.zero,
          ),
        );
      final repo = LastWordRepository(dio);
      final created = await repo.create(
        const LastWord(title: '첫 편지', message: '내용', receiverIds: ['person-1']),
      );
      expect((await repo.list()).any((item) => item.id == created.id), isTrue);
      final updated = await repo.update(
        created.id,
        const LastWord(
          title: '수정한 편지',
          message: '새 내용',
          receiverIds: ['person-1'],
        ),
      );
      expect(updated.title, '수정한 편지');
      await repo.delete(created.id);
      expect((await repo.list()).any((item) => item.id == created.id), isFalse);
      dio.close();
    },
  );
}
