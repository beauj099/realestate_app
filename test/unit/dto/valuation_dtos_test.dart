import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/valuation_dtos.dart';

void main() {
  group('UpsertValuationRequest', () {
    test('toJson() includes non-null fields', () {
      final request = UpsertValuationRequest(
        ownersNetPrice: 2500000,
        commissionPercent: 5.5,
      );

      final json = request.toJson();

      expect(json['ownersNetPrice'], 2500000);
      expect(json['commissionPercent'], 5.5);
      expect(json.containsKey('agentValuation'), false);
    });
  });

  group('ValuationDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'ownersNetPrice': 2500000,
        'agentValuation': 2600000,
        'commissionPercent': 5.5,
      };

      final dto = ValuationDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.ownersNetPrice, 2500000);
      expect(dto.agentValuation, 2600000);
      expect(dto.commissionPercent, 5.5);
    });

    test('fromJson() handles null fields', () {
      final json = {'id': 1};

      final dto = ValuationDto.fromJson(json);

      expect(dto.ownersNetPrice, isNull);
      expect(dto.commissionPercent, isNull);
    });
  });

  group('UpsertRunningCostsRequest', () {
    test('toJson() includes non-null fields', () {
      final request = UpsertRunningCostsRequest(
        monthlyLevy: 1500,
        monthlyRates: 800,
      );

      final json = request.toJson();

      expect(json['monthlyLevy'], 1500);
      expect(json['monthlyRates'], 800);
      expect(json.containsKey('electricity'), false);
    });
  });

  group('RunningCostsDto', () {
    test('fromJson() parses correctly', () {
      final json = {
        'id': 1,
        'listingId': 42,
        'monthlyLevy': 1500,
        'monthlyRates': 800,
      };

      final dto = RunningCostsDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.listingId, 42);
      expect(dto.monthlyLevy, 1500);
      expect(dto.monthlyRates, 800);
    });
  });
}
