import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/property_running_costs.dart';

void main() {
  group('PropertyRunningCosts', () {
    test('constructor sets default empty strings', () {
      const costs = PropertyRunningCosts();

      expect(costs.monthlyLevy, '');
      expect(costs.monthlyRates, '');
      expect(costs.electricity, '');
      expect(costs.water, '');
    });

    test('copyWith() overrides specified fields', () {
      const costs = PropertyRunningCosts();

      final updated = costs.copyWith(monthlyLevy: '1500', monthlyRates: '800');

      expect(updated.monthlyLevy, '1500');
      expect(updated.monthlyRates, '800');
      expect(updated.electricity, '');
    });
  });
}
