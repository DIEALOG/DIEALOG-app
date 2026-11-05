import 'package:diealog_app/data/mock/mock_api_interceptor.dart';
import 'package:diealog_app/data/mock/mock_backend.dart';
import 'package:diealog_app/data/models/last_word.dart';
import 'package:diealog_app/data/models/stakeholder.dart';
import 'package:diealog_app/data/providers.dart';
import 'package:diealog_app/data/repositories/last_word_repository.dart';
import 'package:diealog_app/features/last_word/letter_draft_store.dart';
import 'package:diealog_app/features/last_word/letter_edit_screen.dart';
import 'package:diealog_app/features/last_word/letter_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDraftStore implements LetterDraftStore {
  final drafts = <String, LetterDraft>{};

  @override
  Future<LetterDraft?> read(String userId, String letterId) async =>
      drafts['$userId/$letterId'];

  @override
  Future<void> write(String userId, String letterId, LetterDraft draft) async =>
      drafts['$userId/$letterId'] = draft;

  @override
  Future<void> delete(String userId, String letterId) async =>
      drafts.remove('$userId/$letterId');
}

void main() {
  testWidgets('the delete control sits in the header and removes the letter', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..interceptors.add(
        MockApiInterceptor(
          backend: MockBackend.seeded(),
          latency: Duration.zero,
        ),
      );
    addTearDown(dio.close);
    final repository = LastWordRepository(dio);
    // `runAsync` steps outside the fake clock, which the mock transport's own
    // delay would otherwise wait on forever.
    final letter = (await tester.runAsync(
      () => repository.create(
        const LastWord(
          title: '지울 편지',
          message: '테스트',
          receiverIds: ['person'],
        ),
      ),
    ))!;
    final overview = LetterOverview(
      userId: 'user-1',
      letters: [letter],
      people: const [Stakeholder(id: 'person', name: '친구')],
      groups: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lastWordRepositoryProvider.overrideWithValue(repository),
          letterDraftStoreProvider.overrideWithValue(_FakeDraftStore()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LetterEditScreen(overview: overview, letter: letter),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    // Stepped rather than settled: the editor shows a spinner until the draft
    // store answers, and a spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Reachable without scrolling past the message field, which is where it
    // used to hide.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    final remaining = (await tester.runAsync(repository.list))!;
    expect(remaining.map((item) => item.id), isNot(contains(letter.id)));
    expect(find.text('열기'), findsOneWidget, reason: 'the editor should close');
  });

  testWidgets('an unsaved draft can be thrown away too', (tester) async {
    // The 작성 중 row on the list is backed by this local draft, so without a
    // way to discard it the row has nothing that can clear it.
    final drafts = _FakeDraftStore()
      ..drafts['user-1/new'] = LetterDraft(
        title: '쓰다 만 글',
        message: '아직',
        receiverIds: const [],
        receiverGroupIds: const [],
        savedAt: DateTime.utc(2026, 11, 5),
      );
    const overview = LetterOverview(
      userId: 'user-1',
      letters: [],
      people: [],
      groups: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [letterDraftStoreProvider.overrideWithValue(drafts)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LetterEditScreen(overview: overview),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('쓰다 만 글'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();

    expect(drafts.drafts, isEmpty);
  });
}
