import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/locale/countries.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/core/widgets/country_picker.dart';

Future<void> _open(WidgetTester tester, CountryPickerMode mode) async {
  final theme = RealEstateTheme.crimson();
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showCountryPicker(
              context: context,
              theme: theme,
              mode: mode,
              selected: Country.southAfrica,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('South Africa is pinned first, above a divider', (tester) async {
    await _open(tester, CountryPickerMode.country);
    final za = tester.getTopLeft(find.text('South Africa'));
    final afghanistan = tester.getTopLeft(find.text('Afghanistan'));
    expect(za.dy, lessThan(afghanistan.dy));
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('typing narrows the list to matching countries', (tester) async {
    await _open(tester, CountryPickerMode.country);
    await tester.enterText(find.byType(TextField), 'nam');
    await tester.pumpAndSettle();
    expect(find.text('Namibia'), findsOneWidget);
    expect(find.text('Vietnam'), findsOneWidget);
    expect(find.text('Kenya'), findsNothing);
  });

  testWidgets('currency mode shows symbols and matches currency names', (
    tester,
  ) async {
    await _open(tester, CountryPickerMode.currency);
    expect(find.text('South African Rand'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pula');
    await tester.pumpAndSettle();
    expect(find.text('Botswana'), findsOneWidget);
    expect(find.text('South Africa'), findsNothing);
  });
}
