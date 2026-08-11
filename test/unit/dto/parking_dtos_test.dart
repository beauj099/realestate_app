import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/parking_dtos.dart';

void main() {
  group('AddParkingRequest', () {
    test('toJson() returns correct map', () {
      final request = AddParkingRequest(parkingTypeId: 1, quantity: 2);

      final json = request.toJson();

      expect(json['parkingTypeId'], 1);
      expect(json['quantity'], 2);
    });
  });

  group('UpdateParkingRequest', () {
    test('toJson() returns correct map', () {
      final request = UpdateParkingRequest(quantity: 3);

      final json = request.toJson();

      expect(json['quantity'], 3);
    });
  });

  group('ParkingDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingId': 42,
        'parkingTypeId': 1,
        'quantity': 2,
        'parkingTypeDescription': 'Single Garage',
      };

      final dto = ParkingDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.listingId, 42);
      expect(dto.parkingTypeId, 1);
      expect(dto.quantity, 2);
      expect(dto.parkingTypeDescription, 'Single Garage');
    });
  });
}
