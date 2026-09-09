import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/core/widgets/custom_text_input.dart';

void main() {
  testWidgets('CustomTextInput renders label and placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextInput(
            theme: RealEstateTheme.crimson(),
            label: 'Street Name',
            placeholder: 'e.g. Main Street',
          ),
        ),
      ),
    );

    expect(find.text('Street Name'), findsOneWidget);
  });

  testWidgets('CustomTextInput shows initial value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextInput(
            theme: RealEstateTheme.crimson(),
            label: 'City',
            initialValue: 'Cape Town',
          ),
        ),
      ),
    );

    expect(find.text('Cape Town'), findsOneWidget);
  });

  testWidgets('CustomTextInput calls onChanged when text is entered', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextInput(
            theme: RealEstateTheme.crimson(),
            label: 'Name',
            onChanged: (val) => result = val,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Test Value');
    expect(result, 'Test Value');
  });
}
