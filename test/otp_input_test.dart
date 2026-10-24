import 'package:diealog_app/core/widgets/otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('normalizes paste into six digits and reports completion', (
    tester,
  ) async {
    final controller = TextEditingController();
    String? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInput(
            controller: controller,
            onCompleted: (value) => completed = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12-34 56 extra');
    await tester.pump();

    expect(controller.text, '123456');
    expect(completed, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });
}
