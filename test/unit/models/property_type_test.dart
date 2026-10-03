import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/enums/property_type.dart';

void main() {
  group('PropertyType', () {
    test('ids match the backend PropertyType rows', () {
      // Ordinal position is the backend id; reordering would silently refile
      // every existing listing under a different type.
      expect(PropertyType.house.id, 1);
      expect(PropertyType.townhouse.id, 2);
      expect(PropertyType.apartment.id, 3);
      expect(PropertyType.commercial.id, 4);
      expect(PropertyType.plot.id, 5);
      expect(PropertyType.vacantLand.id, 6);
    });

    test('slot 4 is commercial property; vacant land is its own type', () {
      expect(PropertyType.commercial.displayString, 'Commercial Property');
      expect(PropertyType.vacantLand.displayString, 'Vacant Land');
    });

    test('fromString knows vacant land and commercial property apart', () {
      expect(
        PropertyTypeExtension.fromString('Vacant Land'),
        PropertyType.vacantLand,
      );
      expect(
        PropertyTypeExtension.fromString('vacantland'),
        PropertyType.vacantLand,
      );
      expect(
        PropertyTypeExtension.fromString('Commercial Property'),
        PropertyType.commercial,
      );
    });

    test('fromString is case and whitespace tolerant', () {
      expect(PropertyTypeExtension.fromString('  PLOT '), PropertyType.plot);
      expect(
        PropertyTypeExtension.fromString('Townhouse'),
        PropertyType.townhouse,
      );
    });

    test('fromString falls back to house for anything unknown', () {
      expect(PropertyTypeExtension.fromString('castle'), PropertyType.house);
    });

    test('fromId round-trips every type', () {
      for (final type in PropertyType.values) {
        expect(PropertyTypeExtension.fromId(type.id), type);
      }
    });

    test('fromId returns null when nothing is selected', () {
      // propertyTypeId defaults to 0 on a new listing.
      expect(PropertyTypeExtension.fromId(0), isNull);
      expect(PropertyTypeExtension.fromId(99), isNull);
    });
  });
}
