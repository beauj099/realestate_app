import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/features/property_report/data/models/address_suggestion.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/data/property_report_repository.dart';
import 'package:realworth/features/property_report/presentation/widgets/address_search_field.dart';
import 'package:realworth/features/property_report/providers/property_report_provider.dart';

/// Answers suggestions from memory and counts how often it was asked.
class _FakeRepo implements PropertyReportRepository {
  int calls = 0;
  String? lastQuery;

  @override
  Future<List<AddressSuggestion>> suggest(String text) async {
    calls++;
    lastQuery = text;
    return const [
      AddressSuggestion(
        label: '17 Pine Road, Claremont',
        streetNumber: '17',
        streetName: 'Pine Road',
        suburb: 'Claremont',
        city: 'Cape Town',
        province: 'Western Cape',
        country: 'South Africa',
        erf: '53927',
        lat: -33.98974,
        lng: 18.470992,
      ),
    ];
  }

  @override
  Future<List<PropertyCandidate>> resolve(ReportQuery q) =>
      throw UnimplementedError();
  @override
  Future<PropertyReport> fetchReport(PropertyCandidate c) =>
      throw UnimplementedError();
  @override
  Future<String?> fetchSitePlan(String sitePlanUrl) =>
      throw UnimplementedError();
  @override
  Future<Uint8List?> fetchImage(String url) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'suggests Cape Town addresses after a pause and returns the pick',
    (tester) async {
      final repo = _FakeRepo();
      AddressSuggestion? picked;
      final theme = RealEstateTheme.crimson();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [propertyReportRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: AddressSearchField(
                theme: theme,
                textTheme: Typography.material2021().black,
                onPickCity: (s) => picked = s,
                onPickElsewhere: (_) {},
              ),
            ),
          ),
        ),
      );

      // Typing quickly asks once, for the whole text, after the pause.
      await tester.enterText(find.byType(TextField), '17 p');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), '17 pine');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(repo.calls, 1);
      expect(repo.lastQuery, '17 pine');

      expect(find.text('17 Pine Road, Claremont'), findsOneWidget);
      expect(find.text('Erf 53927 · Cape Town'), findsOneWidget);
      expect(find.textContaining('Search all of South Africa'), findsOneWidget);

      await tester.tap(find.text('17 Pine Road, Claremont'));
      await tester.pump();
      expect(picked?.erf, '53927');
      expect(picked?.isProperty, isTrue);
      // The list closes once an address is chosen.
      expect(find.text('Erf 53927 · Cape Town'), findsNothing);
    },
  );

  testWidgets('does not search for fewer than 3 characters', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [propertyReportRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: AddressSearchField(
              theme: RealEstateTheme.crimson(),
              textTheme: Typography.material2021().black,
              onPickCity: (_) {},
              onPickElsewhere: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '17');
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.calls, 0);
  });
}
