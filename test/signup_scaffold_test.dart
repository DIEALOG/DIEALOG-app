import 'package:diealog_app/features/auth/signup/signup_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _title = '안전하게 사용할\n비밀번호를 만들어주세요';
const _subtitle = '소중한 기록을 안전하게 보호할게요.';
const _footnote = '입력한 내용은 이전 단계에서 수정할 수 있어요.';

Widget _harness(double keyboard) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
      child: SignupScaffold(
        step: 3,
        title: _title,
        subtitle: _subtitle,
        buttonLabel: '다음',
        buttonEnabled: true,
        onNext: () {},
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a closed keyboard shows the full heading', (tester) async {
    await tester.pumpWidget(_harness(0));

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_subtitle), findsOneWidget);
    expect(find.text(_footnote), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open keyboard keeps the title, step and button on screen', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(320));

    // The subtitle and the footnote hint step aside; the heading, the progress
    // and the action have to stay put, with nothing clipped or overflowing.
    expect(find.text(_subtitle), findsNothing);
    expect(find.text(_footnote), findsNothing);
    expect(find.text(_title), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final view = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final button = tester.getRect(find.text('다음'));
    expect(
      button.bottom,
      lessThan(view - 320),
      reason: 'the action must sit above the keyboard, not under it',
    );
  });
}
