import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/contact.dart';
import 'package:realworth/features/property_overview/data/models/listing_parking.dart';
import 'package:realworth/features/property_overview/data/models/listing_valuation.dart';
import 'package:realworth/features/property_overview/data/models/property_running_costs.dart';
import 'package:realworth/features/property_overview/data/models/property_state.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';

void main() {
  group('PropertyState', () {
    test('constructor sets default values', () {
      final state = PropertyState();

      expect(state.propertyTypeId, 0);
      expect(state.street, '');
      expect(state.suburb, '');
      expect(state.city, '');
      expect(state.rooms, isEmpty);
      expect(state.parking, isEmpty);
      expect(state.listingValuation, const ListingValuation());
      expect(state.propertyRunningCosts, const PropertyRunningCosts());
      expect(state.primaryContact, const Contact());
      expect(state.coContacts, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith() overrides specified fields', () {
      final state = PropertyState();

      final updated = state.copyWith(city: 'Johannesburg', street: 'Main St');

      expect(updated.city, 'Johannesburg');
      expect(updated.street, 'Main St');
      expect(updated.propertyTypeId, 0);
    });

    test('copyWith() handles rooms list', () {
      final state = PropertyState();
      final rooms = [Room(id: '1', name: 'Bedroom', roomTypeId: 1)];

      final updated = state.copyWith(rooms: rooms);

      expect(updated.rooms.length, 1);
      expect(updated.rooms.first.name, 'Bedroom');
    });

    test('copyWith() handles parking list', () {
      final state = PropertyState();
      final parking = [const ListingParking(parkingTypeId: 1, quantity: 2)];

      final updated = state.copyWith(parking: parking);

      expect(updated.parking.length, 1);
      expect(updated.parking.first.quantity, 2);
    });

    test('copyWith() handles error message', () {
      final state = PropertyState();

      final updated = state.copyWith(errorMessage: 'Something went wrong');

      expect(updated.errorMessage, 'Something went wrong');
    });

    test('copyWith() handles valuation', () {
      final state = PropertyState();
      final valuation = const ListingValuation(ownersNetPrice: '2500000');

      final updated = state.copyWith(listingValuation: valuation);

      expect(updated.listingValuation.ownersNetPrice, '2500000');
    });

    test('copyWith() preserves fields not specified', () {
      final state = PropertyState(propertyTypeId: 3, street: 'Oak Ave');

      final updated = state.copyWith(city: 'Durban');

      expect(updated.propertyTypeId, 3);
      expect(updated.street, 'Oak Ave');
      expect(updated.city, 'Durban');
    });

    group('copyWith() nullable field clearing', () {
      test('explicit null clears errorMessage', () {
        final state = PropertyState().copyWith(errorMessage: 'boom');
        expect(state.errorMessage, 'boom');

        final cleared = state.copyWith(errorMessage: null);
        expect(cleared.errorMessage, isNull);
      });

      test('explicit null clears selectedRoomId', () {
        final state = PropertyState().copyWith(selectedRoomId: 'room-1');
        expect(state.selectedRoomId, 'room-1');

        final cleared = state.copyWith(selectedRoomId: null);
        expect(cleared.selectedRoomId, isNull);
      });

      test('explicit null clears facingId, zoningId and listingId', () {
        final state = PropertyState().copyWith(
          facingId: 2,
          zoningId: 3,
          listingId: 42,
        );
        expect(state.facingId, 2);
        expect(state.zoningId, 3);
        expect(state.listingId, 42);

        final cleared = state.copyWith(
          facingId: null,
          zoningId: null,
          listingId: null,
        );
        expect(cleared.facingId, isNull);
        expect(cleared.zoningId, isNull);
        expect(cleared.listingId, isNull);
      });

      test('explicit null clears latitude, longitude and p24Ref', () {
        final state = PropertyState().copyWith(
          latitude: -33.9,
          longitude: 18.4,
          p24Ref: 'P24-1',
        );
        expect(state.latitude, -33.9);
        expect(state.longitude, 18.4);
        expect(state.p24Ref, 'P24-1');

        final cleared = state.copyWith(
          latitude: null,
          longitude: null,
          p24Ref: null,
        );
        expect(cleared.latitude, isNull);
        expect(cleared.longitude, isNull);
        expect(cleared.p24Ref, isNull);
      });

      test('omitting a nullable field preserves its value', () {
        final state = PropertyState().copyWith(
          selectedRoomId: 'room-1',
          facingId: 2,
          listingId: 42,
        );

        final updated = state.copyWith(city: 'Cape Town');

        expect(updated.city, 'Cape Town');
        expect(updated.selectedRoomId, 'room-1');
        expect(updated.facingId, 2);
        expect(updated.listingId, 42);
      });
    });
  });
}
