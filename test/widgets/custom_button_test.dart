import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton renders label text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(text: 'Next', onTap: () {}),
        ),
      ),
    );

    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('CustomButton calls onTap when pressed', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(text: 'Submit', onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Submit'));
    expect(tapped, true);
  });

  testWidgets('CustomButton renders when onTap is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomButton(text: 'Disabled')),
      ),
    );

    expect(find.text('Disabled'), findsOneWidget);
  });
}
