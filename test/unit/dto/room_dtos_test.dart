import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/room_dtos.dart';

void main() {
  group('CreateRoomRequest', () {
    test('toJson() returns correct map', () {
      final request = CreateRoomRequest(name: 'Master Bedroom', roomTypeId: 1);

      final json = request.toJson();

      expect(json['name'], 'Master Bedroom');
      expect(json['roomTypeId'], 1);
    });

    test('toJson() includes optional fields when set', () {
      final request = CreateRoomRequest(
        name: 'Study',
        roomTypeId: 4,
        roomTypeOther: 'Home Office',
        photoUrl: '/path/to/photo.jpg',
      );

      final json = request.toJson();

      expect(json['roomTypeOther'], 'Home Office');
      expect(json['photoUrl'], '/path/to/photo.jpg');
    });
  });

  group('UpdateRoomRequest', () {
    test('toJson() includes only set fields', () {
      final request = UpdateRoomRequest(name: 'Updated Name');

      final json = request.toJson();

      expect(json['name'], 'Updated Name');
      expect(json.containsKey('roomTypeId'), false);
    });
  });

  group('UpsertRoomConditionRequest', () {
    test('toJson() includes all fields', () {
      final request = UpsertRoomConditionRequest(
        conditionRating: 3,
        notes: 'Good condition',
        conditionCategoryId: 1,
      );

      final json = request.toJson();

      expect(json['conditionRating'], 3);
      expect(json['notes'], 'Good condition');
      expect(json['conditionCategoryId'], 1);
    });
  });

  group('LinkFeatureRequest', () {
    test('toJson() returns correct map', () {
      final request = LinkFeatureRequest(featureId: 5);

      final json = request.toJson();

      expect(json['featureId'], 5);
    });
  });

  group('AddCustomFeatureRequest', () {
    test('toJson() returns correct map', () {
      final request = AddCustomFeatureRequest(description: 'USB Outlets');

      final json = request.toJson();

      expect(json['description'], 'USB Outlets');
    });
  });

  group('RoomConditionDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingRoomId': 42,
        'conditionRating': 4,
        'notes': 'Perfect',
        'conditionCategoryId': 1,
      };

      final dto = RoomConditionDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.listingRoomId, 42);
      expect(dto.conditionRating, 4);
      expect(dto.conditionCategoryId, 1);
    });
  });

  group('CustomFeatureDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingRoomId': 42,
        'description': 'Underfloor Heating',
      };

      final dto = CustomFeatureDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.description, 'Underfloor Heating');
    });
  });

  group('RoomDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingId': 42,
        'name': 'Living Room',
        'roomTypeId': 3,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final dto = RoomDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.name, 'Living Room');
      expect(dto.features, isEmpty);
      expect(dto.customFeatures, isEmpty);
      expect(dto.condition, isNull);
    });

    test('fromJson() parses with nested objects', () {
      final json = {
        'id': 1,
        'listingId': 42,
        'name': 'Living Room',
        'roomTypeId': 3,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'condition': {
          'id': 1,
          'listingRoomId': 1,
          'conditionRating': 4,
          'conditionCategoryId': 1,
        },
        'features': [
          {'id': 1, 'category': 'General', 'description': 'Aircon'},
        ],
      };

      final dto = RoomDto.fromJson(json);

      expect(dto.condition, isNotNull);
      expect(dto.condition!.conditionRating, 4);
      expect(dto.features.length, 1);
      expect(dto.features.first.description, 'Aircon');
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
}
