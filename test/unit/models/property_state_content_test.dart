import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/contact.dart';
import 'package:realworth/features/property_overview/data/models/property_running_costs.dart';
import 'package:realworth/features/property_overview/data/models/property_state.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';

PropertyState _empty() => PropertyState(listingId: 1, propertyTypeId: 1);

void main() {
  group('sameContentAs', () {
    test('switching owner type with nothing typed is not a change', () {
      final before = _empty();
      final toggled = before.copyWith(
        primaryContact: before.primaryContact
            .asOwnerType(OwnerType.business)
            .asOwnerType(OwnerType.naturalPerson),
      );
      expect(toggled.sameContentAs(before), isTrue);
    });

    test('typing a value and deleting it again is not a change', () {
      final before = _empty();
      final after = before.copyWith(street: 'Main').copyWith(street: '');
      expect(after.sameContentAs(before), isTrue);
    });

    test('an error message or the room being edited is not a change', () {
      final before = _empty();
      final after = before.copyWith(
        errorMessage: 'Network down',
        selectedRoomId: 'r1',
      );
      expect(after.sameContentAs(before), isTrue);
    });

    test('real edits are changes', () {
      final before = _empty();
      expect(before.copyWith(city: 'Cape Town').sameContentAs(before), isFalse);
      expect(
        before
            .copyWith(primaryContact: const Contact(fullName: 'Jane'))
            .sameContentAs(before),
        isFalse,
      );
      expect(
        before
            .copyWith(
              rooms: [Room(id: 'r1', name: 'Bedroom')],
            )
            .sameContentAs(before),
        isFalse,
      );
    });

    test('a room score is a change', () {
      final base = _empty().copyWith(
        rooms: [Room(id: 'r1', name: 'Kitchen')],
      );
      final scored = base.copyWith(
        rooms: [base.rooms.single.copyWith(score: 7.5)],
      );
      expect(scored.sameContentAs(base), isFalse);
    });
  });

  group('hasMeaningfulContent', () {
    test('an untouched listing has nothing worth keeping', () {
      expect(_empty().hasMeaningfulContent, isFalse);
    });

    test('an owner-type toggle alone has nothing worth keeping', () {
      final s = _empty();
      final toggled = s.copyWith(
        primaryContact: s.primaryContact.asOwnerType(OwnerType.business),
      );
      expect(toggled.hasMeaningfulContent, isFalse);
    });

    test('any captured detail is worth keeping', () {
      expect(_empty().copyWith(street: 'Main').hasMeaningfulContent, isTrue);
      expect(
        _empty().copyWith(exteriorPhotos: ['/p.jpg']).hasMeaningfulContent,
        isTrue,
      );
      expect(
        _empty()
            .copyWith(
              propertyRunningCosts: const PropertyRunningCosts(water: '400'),
            )
            .hasMeaningfulContent,
        isTrue,
      );
      expect(
        _empty()
            .copyWith(primaryContact: const Contact(mobilePhone: '082'))
            .hasMeaningfulContent,
        isTrue,
      );
    });
  });

  group('section completeness follows the required fields', () {
    test('address needs street, city and country', () {
      final partial = _empty().copyWith(street: 'Main', city: 'Paarl');
      expect(partial.isAddressComplete, isFalse);
      expect(
        partial.copyWith(country: 'South Africa').isAddressComplete,
        isTrue,
      );
    });

    test('owner needs name, email and phone', () {
      const person = Contact(
        fullName: 'Jane',
        emailAddress: 'j@x.co',
        mobilePhone: '082',
      );
      expect(
        _empty()
            .copyWith(primaryContact: const Contact(fullName: 'Jane'))
            .isOwnerComplete,
        isFalse,
      );
      expect(_empty().copyWith(primaryContact: person).isOwnerComplete, isTrue);
    });

    test('a business owner also needs the company name', () {
      final business = const Contact(
        fullName: 'Jane',
        emailAddress: 'j@x.co',
        mobilePhone: '082',
      ).asOwnerType(OwnerType.business);
      expect(
        _empty().copyWith(primaryContact: business).isOwnerComplete,
        isFalse,
      );
      expect(
        _empty()
            .copyWith(primaryContact: business.copyWith(companyName: 'Acme'))
            .isOwnerComplete,
        isTrue,
      );
    });

    test('expenses count as captured once any cost is entered', () {
      expect(_empty().isExpensesComplete, isFalse);
      expect(
        _empty()
            .copyWith(
              propertyRunningCosts: const PropertyRunningCosts(sewage: '300'),
            )
            .isExpensesComplete,
        isTrue,
      );
    });
  });

  group('houseScore', () {
    test('is null until a room is scored', () {
      final s = _empty().copyWith(
        rooms: [Room(id: 'a', name: 'A')],
      );
      expect(s.houseScore, isNull);
      expect(s.scoredRoomCount, 0);
    });

    test('averages scored rooms and leaves unscored ones out', () {
      final s = _empty().copyWith(
        rooms: [
          Room(id: 'a', name: 'A', score: 8),
          Room(id: 'b', name: 'B', score: 6),
          Room(id: 'c', name: 'C'),
        ],
      );
      // Two bedrooms weigh the same, so this is a plain average, as a percent.
      expect(s.houseScore, 70);
      expect(s.scoredRoomCount, 2);
    });
  });
}
