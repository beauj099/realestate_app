import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/contact_dtos.dart';

void main() {
  group('AddContactRequest', () {
    test('toJson() includes non-empty fields', () {
      final request = AddContactRequest(
        fullName: 'John Doe',
        mobilePhone: '+27123456789',
      );

      final json = request.toJson();

      expect(json['fullName'], 'John Doe');
      expect(json['mobilePhone'], '+27123456789');
      expect(json.containsKey('emailAddress'), false);
    });

    test('toJson() omits empty string fields', () {
      final request = AddContactRequest(fullName: '', idNumber: '');

      final json = request.toJson();

      expect(json.containsKey('fullName'), false);
      expect(json.containsKey('idNumber'), false);
    });
  });

  group('UpdateContactRequest', () {
    test('toJson() includes non-null fields', () {
      final request = UpdateContactRequest(
        fullName: 'Jane Doe',
        role: 'Seller',
      );

      final json = request.toJson();

      expect(json['fullName'], 'Jane Doe');
      expect(json['role'], 'Seller');
    });
  });

  group('ContactDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingId': 42,
        'fullName': 'John Agent',
        'emailAddress': 'john@example.com',
        'mobilePhone': '+27123456789',
        'role': 'Agent',
      };

      final dto = ContactDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.listingId, 42);
      expect(dto.fullName, 'John Agent');
      expect(dto.emailAddress, 'john@example.com');
      expect(dto.role, 'Agent');
    });

    test('fromJson() handles null fields', () {
      final json = {'id': 1, 'listingId': 42};

      final dto = ContactDto.fromJson(json);

      expect(dto.fullName, isNull);
      expect(dto.emailAddress, isNull);
    });
  });
}
