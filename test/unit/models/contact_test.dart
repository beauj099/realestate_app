import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/contact.dart';

void main() {
  group('Contact', () {
    test('constructor sets default empty values', () {
      const contact = Contact();

      expect(contact.id, '');
      expect(contact.fullName, '');
      expect(contact.mobilePhone, '');
      expect(contact.emailAddress, '');
    });

    test('copyWith() overrides specified fields', () {
      const contact = Contact();

      final updated = contact.copyWith(
        fullName: 'John Doe',
        mobilePhone: '+27123456789',
        emailAddress: 'john@example.com',
      );

      expect(updated.fullName, 'John Doe');
      expect(updated.mobilePhone, '+27123456789');
      expect(updated.emailAddress, 'john@example.com');
    });

    test('copyWith() preserves unchanged fields', () {
      const contact = Contact(id: '1', fullName: 'Jane');

      final updated = contact.copyWith(role: 'Seller');

      expect(updated.id, '1');
      expect(updated.fullName, 'Jane');
      expect(updated.role, 'Seller');
    });
  });
}
