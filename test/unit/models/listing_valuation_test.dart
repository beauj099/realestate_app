import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/listing_valuation.dart';

void main() {
  group('ListingValuation', () {
    test('constructor sets default empty strings', () {
      const valuation = ListingValuation();

      expect(valuation.ownersNetPrice, '');
      expect(valuation.agentValuation, '');
      expect(valuation.commissionPercent, '');
    });

    test('copyWith() overrides specified fields', () {
      const valuation = ListingValuation();

      final updated = valuation.copyWith(
        ownersNetPrice: '2500000',
        commissionPercent: '5.5',
      );

      expect(updated.ownersNetPrice, '2500000');
      expect(updated.commissionPercent, '5.5');
      expect(updated.agentValuation, '');
    });
  });
}
