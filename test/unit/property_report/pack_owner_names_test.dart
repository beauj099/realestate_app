import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/report/pack_listing.dart';

void main() {
  group('joinOwnerNames', () {
    test('says a shared surname once', () {
      expect(
        joinOwnerNames(['Piet Swanepoel', 'Mary Swanepoel']),
        'Piet & Mary Swanepoel',
      );
      expect(
        joinOwnerNames(['Francois du Toit', 'Ree du Toit']),
        'Francois & Ree du Toit',
      );
    });

    test('keeps full names when surnames differ', () {
      expect(
        joinOwnerNames(['Bill Murray', 'John Smith']),
        'Bill Murray & John Smith',
      );
    });

    test('lists three owners with commas', () {
      expect(
        joinOwnerNames(['Anna Botha', 'Ben Botha', 'Carl Botha']),
        'Anna, Ben & Carl Botha',
      );
      expect(joinOwnerNames(['Piet Swanepoel']), 'Piet Swanepoel');
      expect(
        joinOwnerNames(['Acme Trust', 'Piet Swanepoel']),
        'Acme Trust & Piet Swanepoel',
      );
    });
  });

  test('splitName keeps surname particles with the surname', () {
    expect(splitName('Mary Anne van der Merwe'), (
      first: 'Mary Anne',
      last: 'van der Merwe',
    ));
    expect(splitName('Francois du Toit'), (first: 'Francois', last: 'du Toit'));
    expect(splitName('Cher'), (first: 'Cher', last: ''));
  });

  group('greetOwners', () {
    test('by title when every owner has one', () {
      expect(
        greetOwners([
          (title: 'Mr', name: 'Piet Swanepoel'),
          (title: 'Mrs', name: 'Mary Swanepoel'),
        ]),
        'Mr & Mrs Swanepoel',
      );
      expect(
        greetOwners([
          (title: 'Mr', name: 'Bill Murray'),
          (title: 'Dr', name: 'John Smith'),
        ]),
        'Mr Murray & Dr Smith',
      );
    });

    test('by first name when a title is missing', () {
      expect(
        greetOwners([
          (title: 'Mr', name: 'Piet Swanepoel'),
          (title: '', name: 'Mary Swanepoel'),
        ]),
        'Piet & Mary',
      );
    });
  });
}
