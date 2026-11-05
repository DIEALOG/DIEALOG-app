import 'package:diealog_app/features/home/home_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Size> _fillSize(WidgetTester tester, double value) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: ProgressBar(
              value: value,
              track: Colors.grey,
              fill: Colors.green,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(AnimatedContainer));
}

void main() {
  test('a fresh account has every guide step open', () {
    final guide = HomeGuide.of(
      accounts: 0,
      people: 0,
      confirmers: 0,
      letters: 0,
    );

    expect(guide.steps, hasLength(4));
    expect(guide.doneCount, 0);
    expect(guide.finished, isFalse);
    expect(guide.next?.kind, HomeGuideKind.data);
  });

  test('steps tick off independently and point at the first one left', () {
    final guide = HomeGuide.of(
      accounts: 2,
      people: 1,
      confirmers: 0,
      letters: 3,
    );

    expect(guide.doneCount, 3);
    expect(guide.finished, isFalse);
    expect(
      guide.next?.kind,
      HomeGuideKind.confirmer,
      reason: 'the only step left is the one with no accepted confirmer',
    );
  });

  test('the guide retires once everything is done', () {
    final guide = HomeGuide.of(
      accounts: 1,
      people: 1,
      confirmers: 2,
      letters: 1,
    );

    expect(guide.doneCount, 4);
    expect(guide.finished, isTrue);
    expect(guide.next, isNull);
  });

  testWidgets('one bar fills by ratio instead of in five fixed steps', (
    tester,
  ) async {
    // The old five-segment bar rounded 3/10 and 3/4 to the same picture.
    expect((await _fillSize(tester, 0.3)).width, 60);
    expect((await _fillSize(tester, 0.75)).width, 150);
    expect(
      (await _fillSize(tester, 0 / 0)).width,
      0,
      reason: 'an empty total must not produce a NaN width',
    );
    expect((await _fillSize(tester, 2)).width, 200, reason: 'clamped to full');
  });
}
