import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/core/widgets/custom_text_input.dart';

void main() {
  testWidgets('CustomTextInput renders floating label and hint', (
    tester,
  ) async {
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
    expect(find.text('e.g. Main Street'), findsOneWidget);
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

  testWidgets('CustomTextInput marks required labels with an asterisk', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextInput(
            theme: RealEstateTheme.crimson(),
            label: 'Email address',
            isRequired: true,
          ),
        ),
      ),
    );

    expect(find.text('Email address *'), findsOneWidget);
  });

  testWidgets('CustomTextInput shows helper and error text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CustomTextInput(
                theme: RealEstateTheme.crimson(),
                label: 'Nickname',
                subtext: 'Visible to buyers',
              ),
              CustomTextInput(
                theme: RealEstateTheme.crimson(),
                label: 'Email address',
                errorText: 'Enter a valid email',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Visible to buyers'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('a shown password is never capitalised or autocorrected', (
    tester,
  ) async {
    for (final obscure in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextInput(
              theme: RealEstateTheme.crimson(),
              label: 'Password',
              obscureText: obscure,
              isPassword: true,
            ),
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.keyboardType, TextInputType.visiblePassword);
    }
  });
}
