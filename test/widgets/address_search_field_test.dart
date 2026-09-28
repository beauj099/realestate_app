import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/features/property_report/data/models/address_suggestion.dart';
import 'package:realworth/features/property_report/data/models/agent_sales.dart';
import 'package:realworth/features/property_report/data/models/area_details.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/data/property_report_repository.dart';
import 'package:realworth/features/property_report/presentation/widgets/address_search_field.dart';
import 'package:realworth/features/property_report/providers/property_report_provider.dart';

/// Answers suggestions from memory and counts how often it was asked: the
/// City records answer with the erf, OpenStreetMap with the same address as a
/// street and with a suburb.
class _FakeRepo implements PropertyReportRepository {
  int calls = 0;
  final queries = <String>[];

  @override
  Future<List<AddressSuggestion>> suggest(
    String text, {
    bool national = false,
    double? lat,
    double? lng,
  }) async {
    calls++;
    queries.add(text);
    if (national) {
      return const [
        AddressSuggestion(
          kind: SuggestionKind.street,
          title: '17 Pine Road',
          subtitle: 'Claremont, Cape Town',
          streetNumber: '17',
          streetName: 'Pine Road',
          suburb: 'Claremont',
          city: 'Cape Town',
          province: 'Western Cape',
          country: 'South Africa',
          source: 'OpenStreetMap',
          rank: 92,
          key: 'place 17 pine road claremont',
        ),
        AddressSuggestion(
          kind: SuggestionKind.area,
          title: 'Pinelands',
          subtitle: 'Cape Town, Western Cape',
          streetName: '',
          suburb: 'Pinelands',
          city: 'Cape Town',
          province: 'Western Cape',
          country: 'South Africa',
          source: 'OpenStreetMap',
          rank: 50,
          key: 'area pinelands western cape',
        ),
      ];
    }
    return const [
      AddressSuggestion(
        kind: SuggestionKind.property,
        title: '17 Pine Road',
        subtitle: 'Claremont, Cape Town',
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
        numberVerified: true,
        source: 'City records',
        rank: 118,
        key: 'place 17 pine road claremont',
      ),
    ];
  }

  @override
  Future<List<PropertyCandidate>> resolve(ReportQuery q) =>
      throw UnimplementedError();

  @override
  Future<AreaDetails> fetchArea(double lat, double lng) =>
      throw UnimplementedError();

  @override
  Future<ForSale> fetchForSale(
    PropertyReport report, {
    int? bedrooms,
    double? floorM2,
    double? erfM2,
    int? p24Suburb,
    int max = 3,
  }) => throw UnimplementedError();

  @override
  Future<bool> addAgentSale(NewAgentSale sale) => throw UnimplementedError();

  @override
  Future<void> deleteAgentSale(String id) => throw UnimplementedError();

  @override
  Future<List<MarketListing>> fetchMarket(
    String suburb, {
    int? excludeListingId,
  }) => throw UnimplementedError();
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
    'searches City records and all of South Africa at once, as one list',
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
                onPick: (s) => picked = s,
                useDeviceLocation: false,
              ),
            ),
          ),
        ),
      );

      // Typing quickly searches once, for the whole text, after the pause:
      // the City records and the national search together.
      await tester.enterText(find.byType(TextField), '17 p');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), '17 pine');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(repo.calls, 2);
      expect(repo.queries, ['17 pine', '17 pine']);

      // The same address from both sources is one row (the erf); the far
      // weaker suburb is left off. No "search elsewhere" step.
      expect(find.text('Claremont, Cape Town'), findsOneWidget);
      expect(find.text('Pinelands'), findsNothing);
      expect(find.textContaining('Search all'), findsNothing);

      await tester.tap(find.text('Claremont, Cape Town'));
      await tester.pump();
      expect(picked?.erf, '53927');
      expect(picked?.isProperty, isTrue);
      // The list closes once an address is chosen.
      expect(find.text('Claremont, Cape Town'), findsNothing);
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
              onPick: (_) {},
              useDeviceLocation: false,
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
