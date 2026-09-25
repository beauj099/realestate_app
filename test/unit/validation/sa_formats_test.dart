import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/network/dto/listing_dtos.dart';
import 'package:realworth/core/network/photo_urls.dart';
import 'package:realworth/core/validation/sa_formats.dart';
import 'package:realworth/features/property_overview/data/models/contact.dart';
import 'package:realworth/features/property_overview/presentation/widgets/contact_fields.dart';

TextEditingValue _type(TextInputFormatter f, String text) => f.formatEditUpdate(
  TextEditingValue.empty,
  TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  ),
);

void main() {
  group('SA ID number', () {
    test('a valid number passes and describes its holder', () {
      expect(SaIdNumber.validate('8312060001089'), isNull);
      final info = SaIdNumber.parse('831206 0001 089')!;
      expect(info.dateOfBirth, DateTime(1983, 12, 6));
      expect(info.isFemale, isTrue);
      expect(info.isCitizen, isTrue);
    });

    test('a wrong check digit fails', () {
      expect(SaIdNumber.validate('8102195006087'), isNotNull);
    });

    test('length, date and citizenship digit are checked', () {
      expect(SaIdNumber.validate('83120600010'), contains('13 digits'));
      // 31 Feb does not exist.
      expect(SaIdNumber.validate('8302310001080'), contains('birth date'));
      // Citizenship digit must be 0 or 1.
      expect(SaIdNumber.validate('8312060001289'), isNotNull);
    });

    test('is shown grouped as YYMMDD GGGG CCC', () {
      expect(SaIdNumber.format('8312060001089'), '831206 0001 089');
      expect(SaIdNumber.format('83120600'), '831206 00');
    });
  });

  group('SA phone number', () {
    test('accepts local, +27 and spaced forms alike', () {
      for (final input in ['0845003483', '+27845003483', '84 500 3483']) {
        expect(SaPhone.nationalDigits(input), '845003483', reason: input);
        expect(SaPhone.validate(input), isNull, reason: input);
      }
    });

    test('is stored with +27 and shown after the fixed prefix', () {
      expect(SaPhone.toStored('084 500 3483'), '+27845003483');
      expect(SaPhone.format('+27845003483'), '84 500 3483');
      expect(SaPhone.toStored(''), '');
    });

    test('rejects the wrong length or an impossible first digit', () {
      expect(SaPhone.validate('84500348'), isNotNull);
      expect(SaPhone.validate('945003483'), isNotNull);
    });
  });

  group('grouped digit entry', () {
    test('keeps digits only and inserts the spaces itself', () {
      final f = GroupedDigitsFormatter(const [6, 4, 3]);
      expect(_type(f, '83a1206-0001089999').text, '831206 0001 089');
    });

    test('drops the trunk 0 on a phone number', () {
      final f = GroupedDigitsFormatter(const [
        2,
        3,
        4,
      ], normalize: SaPhone.nationalDigits);
      expect(_type(f, '0845003483').text, '84 500 3483');
    });
  });

  group('owner validation', () {
    test('the primary owner needs name, email and phone', () {
      final errors = validateContact(const Contact(), isPrimary: true);
      expect(errors.keys, containsAll(['name', 'email', 'phone']));
    });

    test('co-owners only need what is filled in to be valid', () {
      expect(validateContact(const Contact(), isPrimary: false), isEmpty);
      final errors = validateContact(
        const Contact(
          emailAddress: 'not-an-email',
          idNumber: '8102195006087',
          mobilePhone: '+2712',
        ),
        isPrimary: false,
      );
      expect(errors.keys, containsAll(['email', 'id', 'phone']));
    });

    test('a complete, valid owner has no errors', () {
      const owner = Contact(
        fullName: 'Karien Beaurain',
        idNumber: '8312060001089',
        emailAddress: 'karien@example.com',
        mobilePhone: '+27845003483',
      );
      expect(validateContact(owner, isPrimary: true), isEmpty);
    });
  });

  group('listing cards', () {
    ListingSummaryDto listing({List<String> owners = const []}) =>
        ListingSummaryDto(
          id: 1,
          referenceNumber: 'LST-2026-00018',
          propertyTypeId: 1,
          status: 'incomplete',
          createdAt: DateTime(2026, 9, 25),
          updatedAt: DateTime(2026, 9, 25),
          streetNumber: '9',
          street: 'Cinsaut Street',
          city: 'Somerset West',
          ownerNames: owners,
        );

    test('show every owner, primary first', () {
      expect(listing(owners: ['Walter White']).ownersLine, 'Walter White');
      expect(
        listing(owners: ['Walter White', 'Sarah White']).ownersLine,
        'Walter White & Sarah White',
      );
      expect(listing(owners: ['A', 'B', 'C', 'D']).ownersLine, 'A, B +2');
    });

    test('search text covers address, owners and reference', () {
      final text = listing(owners: ['Sarah White']).searchText;
      expect(text, contains('cinsaut'));
      expect(text, contains('sarah white'));
      expect(text, contains('lst-2026-00018'));
    });
  });

  group('photo paths', () {
    test('device files are not mistaken for server photos', () {
      expect(isRemotePhoto('/data/user/0/app/cache/shot.jpg'), isFalse);
      expect(isRemotePhoto('/uploads/listings/1/a.jpg'), isTrue);
      expect(isRemotePhoto('https://cdn.example.com/a.jpg'), isTrue);
      expect(
        resolvePhotoUrl('/uploads/a.jpg', 'https://api.test'),
        'https://api.test/uploads/a.jpg',
      );
    });
  });
}
