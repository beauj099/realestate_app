import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/nominatim_result.dart';

void main() {
  group('NominatimResult.fromJson', () {
    test('uses address.house_number when present', () {
      final result = NominatimResult.fromJson({
        'display_name': '12 Long Street, Cape Town',
        'lat': '-33.9249',
        'lon': '18.4241',
        'address': {'house_number': '12', 'road': 'Long Street'},
      });

      expect(result.houseNumber, '12');
      expect(result.road, 'Long Street');
    });

    test('accepts a numeric house_number without throwing', () {
      final result = NominatimResult.fromJson({
        'display_name': 'somewhere',
        'address': {'house_number': 12},
      });

      expect(result.houseNumber, '12');
    });

    test('recovers the number from display_name when the field is absent', () {
      // Reverse geocoding a GPS fix usually resolves to the road, so
      // house_number is missing even though display_name carries it.
      final result = NominatimResult.fromJson({
        'display_name': '12 Long Street, Cape Town, 8001, South Africa',
        'address': {'road': 'Long Street', 'city': 'Cape Town'},
      });

      expect(result.houseNumber, '12');
    });

    test('recovers a bare leading number segment', () {
      final result = NominatimResult.fromJson({
        'display_name': '12, Long Street, Cape Town',
        'address': {'road': 'Long Street'},
      });

      expect(result.houseNumber, '12');
    });

    test('handles unit-suffixed and ranged numbers', () {
      expect(
        NominatimResult.fromJson({
          'display_name': '12A Long Street, Cape Town',
          'address': <String, dynamic>{},
        }).houseNumber,
        '12A',
      );
      expect(
        NominatimResult.fromJson({
          'display_name': '12-14 Long Street, Cape Town',
          'address': <String, dynamic>{},
        }).houseNumber,
        '12-14',
      );
    });

    test('returns null when the address genuinely has no number', () {
      final result = NominatimResult.fromJson({
        'display_name': 'Long Street, Cape Town, South Africa',
        'address': {'road': 'Long Street'},
      });

      expect(result.houseNumber, isNull);
    });

    test('treats blank strings as absent', () {
      final result = NominatimResult.fromJson({
        'display_name': '',
        'address': {'house_number': '   ', 'road': ''},
      });

      expect(result.houseNumber, isNull);
      expect(result.road, isNull);
    });

    test('cityOrTown falls back through city, town, village', () {
      expect(
        NominatimResult.fromJson({
          'address': {'village': 'Greyton'},
        }).cityOrTown,
        'Greyton',
      );
      expect(
        NominatimResult.fromJson({
          'address': {'town': 'Hermanus', 'village': 'Greyton'},
        }).cityOrTown,
        'Hermanus',
      );
    });
  });
}
