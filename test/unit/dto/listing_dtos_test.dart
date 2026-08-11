import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/listing_dtos.dart';

void main() {
  group('CreateListingRequest', () {
    test('toJson() returns correct map', () {
      final request = CreateListingRequest(propertyTypeId: 1);

      final json = request.toJson();

      expect(json['propertyTypeId'], 1);
      expect(json.containsKey('p24Ref'), false);
    });

    test('toJson() includes p24Ref when set', () {
      final request = CreateListingRequest(
        propertyTypeId: 2,
        p24Ref: 'P24-123',
      );

      final json = request.toJson();

      expect(json['propertyTypeId'], 2);
      expect(json['p24Ref'], 'P24-123');
    });
  });

  group('UpdateListingRequest', () {
    test('toJson() includes only set fields', () {
      final request = UpdateListingRequest(status: 'active');

      final json = request.toJson();

      expect(json['status'], 'active');
      expect(json.containsKey('p24Ref'), false);
    });
  });

  group('ListingSummaryDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'referenceNumber': 'REF-001',
        'propertyTypeId': 1,
        'status': 'draft',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final dto = ListingSummaryDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.referenceNumber, 'REF-001');
      expect(dto.propertyTypeId, 1);
      expect(dto.status, 'draft');
    });

    test('fromJson() handles nullable fields', () {
      final json = {
        'id': 1,
        'referenceNumber': 'REF-001',
        'propertyTypeId': 1,
        'status': 'draft',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final dto = ListingSummaryDto.fromJson(json);

      expect(dto.p24Ref, isNull);
      expect(dto.listDate, isNull);
    });
  });

  group('ListingResponse', () {
    test('fromJson() parses full response', () {
      final json = {
        'id': 1,
        'referenceNumber': 'REF-001',
        'propertyTypeId': 1,
        'status': 'draft',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final response = ListingResponse.fromJson(json);

      expect(response.id, 1);
      expect(response.referenceNumber, 'REF-001');
      expect(response.rooms, isEmpty);
      expect(response.parking, isEmpty);
      expect(response.contacts, isEmpty);
    });
  });
}
