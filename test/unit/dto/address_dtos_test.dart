import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/address_dtos.dart';

void main() {
  group('UpsertAddressRequest', () {
    test('toJson() includes non-null, non-empty fields only', () {
      final request = UpsertAddressRequest(
        streetNumber: '123',
        street: 'Main St',
        city: 'Cape Town',
      );

      final json = request.toJson();

      expect(json['streetNumber'], '123');
      expect(json['street'], 'Main St');
      expect(json['city'], 'Cape Town');
      expect(json.containsKey('suburb'), false);
      expect(json.containsKey('postalCode'), false);
    });

    test('toJson() omits empty string fields', () {
      final request = UpsertAddressRequest(streetNumber: '', street: '');

      final json = request.toJson();

      expect(json.containsKey('streetNumber'), false);
      expect(json.containsKey('street'), false);
    });

    test('toJson() includes latitude and longitude when set', () {
      final request = UpsertAddressRequest(
        latitude: -33.9249,
        longitude: 18.4241,
      );

      final json = request.toJson();

      expect(json['latitude'], -33.9249);
      expect(json['longitude'], 18.4241);
    });
  });

  group('ListingAddressDto', () {
    test('fromJson() parses full response correctly', () {
      final json = {
        'listingAddressId': 1,
        'listingId': 42,
        'streetNumber': '123',
        'street': 'Main St',
        'suburb': 'Strand',
        'city': 'Cape Town',
        'province': 'Western Cape',
        'country': 'South Africa',
        'postalCode': '7140',
      };

      final dto = ListingAddressDto.fromJson(json);

      expect(dto.listingAddressId, 1);
      expect(dto.listingId, 42);
      expect(dto.street, 'Main St');
      expect(dto.city, 'Cape Town');
      expect(dto.country, 'South Africa');
    });

    test('fromJson() handles nullable fields', () {
      final json = {'listingAddressId': 1, 'listingId': 42};

      final dto = ListingAddressDto.fromJson(json);

      expect(dto.listingAddressId, 1);
      expect(dto.street, isNull);
      expect(dto.latitude, isNull);
    });
  });
}
