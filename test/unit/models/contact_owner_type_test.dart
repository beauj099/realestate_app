import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/contact.dart';

void main() {
  group('Contact owner type', () {
    test('defaults to a natural person', () {
      expect(const Contact().ownerType, OwnerType.naturalPerson);
    });

    test('infers business from a loaded company name', () {
      // Contacts from the API carry no owner-type field, so the type is
      // inferred from which fields are populated.
      const contact = Contact(
        fullName: 'Jane Doe',
        companyName: 'Acme Properties',
      );
      expect(contact.ownerType, OwnerType.business);
    });

    test('infers business from a registration number alone', () {
      const contact = Contact(companyRegistrationNumber: '2021/123456/07');
      expect(contact.ownerType, OwnerType.business);
    });

    test('an explicit choice wins over inference', () {
      final contact = const Contact(
        companyName: 'Acme Properties',
      ).asOwnerType(OwnerType.naturalPerson);
      expect(contact.ownerType, OwnerType.naturalPerson);
    });

    test('switching to a person clears company fields', () {
      const business = Contact(
        fullName: 'Jane Doe',
        idNumber: '8001015009087',
        companyName: 'Acme Properties',
        companyRegistrationNumber: '2021/123456/07',
        emailAddress: 'jane@acme.co.za',
      );

      final person = business.asOwnerType(OwnerType.naturalPerson);

      expect(person.companyName, isEmpty);
      expect(person.companyRegistrationNumber, isEmpty);
      // Shared fields survive the switch.
      expect(person.fullName, 'Jane Doe');
      expect(person.idNumber, '8001015009087');
      expect(person.emailAddress, 'jane@acme.co.za');
    });

    test('switching to a business clears the ID number', () {
      const person = Contact(
        fullName: 'Jane Doe',
        idNumber: '8001015009087',
        mobilePhone: '0820000000',
      );

      final business = person.asOwnerType(OwnerType.business);

      expect(business.idNumber, isEmpty);
      expect(business.ownerType, OwnerType.business);
      expect(business.fullName, 'Jane Doe');
      expect(business.mobilePhone, '0820000000');
    });

    test('a switched-to business reports its type before a name is typed', () {
      // Regression: inference alone would call this a natural person and flip
      // the form back mid-edit.
      final business = const Contact().asOwnerType(OwnerType.business);
      expect(business.ownerType, OwnerType.business);
      expect(business.companyName, isEmpty);
    });

    test('copyWith preserves the selected type', () {
      final business = const Contact().asOwnerType(OwnerType.business);
      final renamed = business.copyWith(companyName: 'Acme');
      expect(renamed.ownerType, OwnerType.business);
    });
  });
}
