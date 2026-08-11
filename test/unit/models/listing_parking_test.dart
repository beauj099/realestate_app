import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/features/property_wizard/data/models/listing_parking.dart';

void main() {
  group('ListingParking', () {
    test('constructor sets default values', () {
      const parking = ListingParking();

      expect(parking.id, '');
      expect(parking.parkingTypeId, 1);
      expect(parking.quantity, 1);
    });

    test('copyWith() overrides specified fields', () {
      const parking = ListingParking();

      final updated = parking.copyWith(parkingTypeId: 2, quantity: 3, id: 'p1');

      expect(updated.parkingTypeId, 2);
      expect(updated.quantity, 3);
      expect(updated.id, 'p1');
    });
  });
}
