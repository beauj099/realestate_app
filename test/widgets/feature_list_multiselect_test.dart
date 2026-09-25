import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/core/widgets/feature_list_widget.dart';

void main() {
  testWidgets('the add sheet takes several features in one go', (tester) async {
    final theme = RealEstateTheme.crimson();
    final added = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeatureListWidget(
            selectedFeatures: const [],
            availableDefaults: const ['Solar Panels', 'Borehole', 'Generator'],
            onAdd: added.add,
            onRemove: (_) {},
            categoryLabel: 'Energy & Water',
            theme: theme,
            textTheme: theme.toThemeData().textTheme,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add Energy & Water'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solar Panels'));
    await tester.tap(find.text('Generator'));
    await tester.pump();

    // The sheet stays open while ticking, then adds everything at once.
    await tester.tap(find.text('Add (2)'));
    await tester.pumpAndSettle();

    expect(added, ['Solar Panels', 'Generator']);
  });
}
