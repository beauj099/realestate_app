import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/enums/room_category.dart';
import 'package:realworth/features/property_overview/data/models/enums/standard_amenity.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';
import 'package:realworth/features/property_overview/data/models/room_score.dart';

void main() {
  group('room amenities', () {
    test('no room is offered whole-house items like alarms or CCTV', () {
      for (final category in RoomCategory.values) {
        final offered = StandardAmenity.relevantForCategory(category);
        expect(
          offered.where((a) => a.category == AmenityCategory.legacyWholeHouse),
          isEmpty,
          reason: category.displayString,
        );
      }
    });

    test('bathrooms are offered bathroom fittings', () {
      final bathroom = StandardAmenity.relevantForCategory(
        RoomCategory.bathroom,
      );
      expect(bathroom, contains(StandardAmenity.bath));
      expect(bathroom, contains(StandardAmenity.shower));
      expect(bathroom, isNot(contains(StandardAmenity.airConditioning)));
    });

    test('bedrooms are not offered kitchen or bathroom fittings', () {
      final bedroom = StandardAmenity.relevantForCategory(RoomCategory.bedroom);
      expect(
        bedroom.where(
          (a) =>
              a.category == AmenityCategory.kitchen ||
              a.category == AmenityCategory.bathroom,
        ),
        isEmpty,
      );
    });

    test(
      'existing feature names are unchanged, so saved rooms still match',
      () {
        expect(StandardAmenity.fromString('Walk-in Closet'), isNotNull);
        expect(StandardAmenity.fromString('Tiled Floors'), isNotNull);
        expect(
          StandardAmenity.fromString('CCTV / Security Cameras'),
          isNotNull,
        );
      },
    );
  });

  test('a new room starts with nothing ticked and no score', () {
    final room = Room(id: '1', name: 'Bedroom');
    expect(room.features, isEmpty);
    expect(room.score, isNull);
  });

  test('copyWith can clear a score', () {
    final scored = Room(id: '1', name: 'Bedroom', score: 6.5);
    expect(scored.copyWith(name: 'Main').score, 6.5);
    expect(scored.copyWith(score: null).score, isNull);
  });

  group('RoomScore', () {
    test('formats without a trailing .0', () {
      expect(RoomScore.format(8), '8');
      expect(RoomScore.format(7.5), '7.5');
      expect(RoomScore.format(6.666), '6.7');
    });

    test('labels the bands', () {
      expect(RoomScore.label(2), 'Poor');
      expect(RoomScore.label(4.5), 'Fair');
      expect(RoomScore.label(6), 'Good');
      expect(RoomScore.label(8), 'Very good');
      expect(RoomScore.label(10), 'Excellent');
    });
  });
}
