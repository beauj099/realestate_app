import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/network/dto/listing_dtos.dart';
import 'package:realworth/features/home/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Regression test: the card's stretched Row inside the ListView used to throw
// "BoxConstraints forces an infinite height", freezing the home screen as soon
// as one listing existed.
Future<void> _pumpHome(
  WidgetTester tester,
  ListingSummaryDto listing, {
  List<ListingSummaryDto> more = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingsProvider.overrideWith((ref) async => [listing, ...more]),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('a listing without an address shows as a draft', (tester) async {
    await _pumpHome(
      tester,
      ListingSummaryDto(
        id: 1,
        referenceNumber: 'LST-2026-00001',
        propertyTypeId: 1,
        status: 'incomplete',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
      ),
    );

    expect(tester.takeException(), isNull);
    // With nothing else to show, the drafts group is open.
    expect(
      find.textContaining('Drafts (1)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('LST-2026-00001'), findsOneWidget);
    expect(find.byTooltip('Delete draft'), findsOneWidget);
  });

  testWidgets('drafts collapse below listings that have an address', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      ListingSummaryDto(
        id: 3,
        referenceNumber: 'LST-2026-00003',
        propertyTypeId: 1,
        status: 'incomplete',
        createdAt: DateTime(2026, 9, 22),
        updatedAt: DateTime(2026, 9, 22),
        streetNumber: '9',
        street: 'Cinsaut Street',
      ),
      more: [
        ListingSummaryDto(
          id: 4,
          referenceNumber: 'LST-2026-00004',
          propertyTypeId: 1,
          status: 'incomplete',
          createdAt: DateTime(2026, 9, 23),
          updatedAt: DateTime(2026, 9, 23),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Cinsaut Street'), findsOneWidget);
    expect(
      find.textContaining('Drafts (1)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('LST-2026-00004'), findsNothing);

    await tester.tap(find.textContaining('Drafts (1)', findRichText: true));
    await tester.pump();
    expect(find.text('LST-2026-00004'), findsOneWidget);
  });

  testWidgets('Home screen lays out a fully populated listing card', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      ListingSummaryDto(
        id: 2,
        referenceNumber: 'LST-2026-00002',
        propertyTypeId: 2,
        status: 'submitted',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        streetNumber: '12',
        street: 'A Very Long Street Name That Wraps Onto Two Lines',
        suburb: 'Some Suburb',
        city: 'Cape Town',
        primaryOwnerName: 'Jane Owner',
        primaryPhotoUrl: 'https://example.invalid/photo.jpg',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Jane Owner'), findsOneWidget);
    expect(
      find.textContaining('Submitted', findRichText: true),
      findsOneWidget,
    );
  });
}
