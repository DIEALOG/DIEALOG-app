import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/last_word.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/repositories/last_word_repository.dart';
import 'package:diealog_app/data/repositories/stakeholder_repository.dart';
import 'package:diealog_app/features/last_word/letter_draft_store.dart';
import 'package:diealog_app/features/shared/audience_picker.dart';
import 'package:diealog_app/features/shared/audience_select_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  testWidgets('a newly created group can be selected as the letter recipient', (
    tester,
  ) async {
    const group = StakeholderGroup(
      id: 'family',
      name: '가족',
      stakeholderIds: ['one', 'two'],
    );
    AudienceSelection? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<AudienceSelection>(
                MaterialPageRoute(
                  builder: (_) => AudienceSelectScreen(
                    people: const [
                      Stakeholder(id: 'one', name: '첫째'),
                      Stakeholder(id: 'two', name: '둘째'),
                    ],
                    groups: const [],
                    initial: const AudienceSelection(),
                    onCreateGroup: () async => [group],
                  ),
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('그룹 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('가족'));
    await tester.pumpAndSettle();
    expect(find.text('2명 선택'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(result?.groups, {'family'});
    expect(result?.people, isEmpty);
  });

  test('a group recipient survives create, read, and update', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    addTearDown(dio.close);
    final group = (await StakeholderRepository(dio).listGroups()).first;
    final repo = LastWordRepository(dio);
    final created = await repo.create(
      LastWord(title: '가족에게', message: '고마워', receiverGroupIds: [group.id]),
    );
    expect(created.receiverGroupIds, [group.id]);
    expect(created.receiverIds, isEmpty);
    expect((await repo.get(created.id)).receiverGroups.single.name, group.name);
    final updated = await repo.update(
      created.id,
      LastWord(
        title: '가족에게 다시',
        message: '늘 고마워',
        receiverGroupIds: [group.id],
      ),
    );
    expect(updated.receiverGroupIds, [group.id]);
    expect(updated.receiverIds, isEmpty);
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
