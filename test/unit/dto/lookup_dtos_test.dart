import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/lookup_dtos.dart';

void main() {
  group('PropertyTypeDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'name': 'House', 'sortOrder': 1, 'isActive': true};

      final dto = PropertyTypeDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.name, 'House');
      expect(dto.sortOrder, 1);
      expect(dto.isActive, true);
    });
  });

  group('RoomTypeDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'description': 'Bedroom'};

      final dto = RoomTypeDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.description, 'Bedroom');
    });
  });

  group('FeatureDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'category': 'General', 'description': 'Aircon'};

      final dto = FeatureDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.category, 'General');
      expect(dto.description, 'Aircon');
    });
  });

  group('ConditionCategoryDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'description': 'Good'};

      final dto = ConditionCategoryDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.description, 'Good');
    });
  });

  group('ParkingTypeDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'description': 'Single Garage'};

      final dto = ParkingTypeDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.description, 'Single Garage');
    });
  });

  group('FacingDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'description': 'North'};

      final dto = FacingDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.description, 'North');
    });
  });

  group('ZoningDto', () {
    test('fromJson() parses correctly', () {
      final json = {'id': 1, 'description': 'Residential'};

      final dto = ZoningDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.description, 'Residential');
    });
  });
}
