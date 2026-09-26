import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/features/property_overview/data/models/enums/condition_rating.dart';
import 'package:realworth/features/property_overview/presentation/widgets/condition_scale.dart';

void main() {
  Widget host(
    ConditionRating? selected,
    ValueChanged<ConditionRating> onChanged,
  ) {
    final theme = RealEstateTheme.crimson();
    return MaterialApp(
      home: Scaffold(
        body: ConditionScale(
          selected: selected,
          onChanged: onChanged,
          theme: theme,
          textTheme: Typography.material2021().black,
        ),
      ),
    );
  }

  testWidgets('offers all six bands, worst to best, and prompts to rate', (
    tester,
  ) async {
    await tester.pumpWidget(host(null, (_) {}));
    for (final rating in ConditionRating.values) {
      expect(find.text(rating.shortLabel), findsOneWidget);
    }
    expect(find.text('Tap one to rate this room'), findsOneWidget);
  });

  testWidgets('tapping a band reports that single rating', (tester) async {
    ConditionRating? picked;
    await tester.pumpWidget(host(null, (r) => picked = r));
    await tester.tap(find.text('Renovate'));
    expect(picked, ConditionRating.toBeRenovated);
  });

  testWidgets('spells out the chosen rating', (tester) async {
    await tester.pumpWidget(host(ConditionRating.excellent, (_) {}));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('As new, or recently renovated', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Tap one to rate this room'), findsNothing);
  });

  test('colours run from red through grey to green', () {
    final red = ConditionRating.toBeRemodeled.scaleColor;
    final green = ConditionRating.excellent.scaleColor;
    expect(red.r, greaterThan(red.g));
    expect(green.g, greaterThan(green.r));
  });
}
