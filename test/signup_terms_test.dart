import 'package:diealog_app/features/auth/signup/signup_terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('marketing consent is optional for signup', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupTermsScreen())),
    );

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '동의하고 가입하기'),
    );

    expect(button().onPressed, isNull);
    await tester.tap(find.text('개인정보 제3자 해외이전 사전동의 (필수)'));
    await tester.tap(find.text('개인정보 처리방침 (필수)'));
    await tester.pump();

    expect(button().onPressed, isNotNull);
    expect(find.text('마케팅 수신 동의 (선택)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
