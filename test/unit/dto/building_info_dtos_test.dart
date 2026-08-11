import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/building_info_dtos.dart';

void main() {
  group('UpsertBuildingInfoRequest', () {
    test('toJson() includes only non-null fields', () {
      final request = UpsertBuildingInfoRequest(erfSize: 500, floorArea: 200);

      final json = request.toJson();

      expect(json['erfSize'], 500);
      expect(json['floorArea'], 200);
      expect(json.containsKey('constructionYear'), false);
      expect(json.containsKey('facingId'), false);
    });

    test('toJson() includes all fields when set', () {
      final request = UpsertBuildingInfoRequest(
        erfSize: 500,
        floorArea: 200,
        constructionYear: 2020,
        facingId: 1,
        zoningId: 3,
      );

      final json = request.toJson();

      expect(json['erfSize'], 500);
      expect(json['constructionYear'], 2020);
      expect(json['facingId'], 1);
      expect(json['zoningId'], 3);
    });
  });

  group('BuildingInfoDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingId': 42,
        'erfSize': 500.0,
        'floorArea': 200.0,
        'constructionYear': 2020,
        'facingId': 1,
        'zoningId': 3,
      };

      final dto = BuildingInfoDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.listingId, 42);
      expect(dto.erfSize, 500.0);
      expect(dto.floorArea, 200.0);
      expect(dto.constructionYear, 2020);
      expect(dto.facingId, 1);
      expect(dto.zoningId, 3);
    });

    test('fromJson() handles null numeric fields', () {
      final json = {'id': 1, 'listingId': 42};

      final dto = BuildingInfoDto.fromJson(json);

      expect(dto.erfSize, isNull);
      expect(dto.facingId, isNull);
    });
  });
}
