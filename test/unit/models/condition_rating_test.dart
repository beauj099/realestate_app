import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/enums/condition_rating.dart';

void main() {
  group('ConditionRating', () {
    test('exposes six bands in worst-to-best order', () {
      expect(ConditionRating.values.length, 6);
      expect(
        ConditionRating.values.map((r) => r.label).toList(),
        [
          'To be remodeled',
          'To be renovated',
          'Average',
          'Good',
          'Very good',
          'Excellent',
        ],
      );
    });

    test('levels are 1-6 and match ordinal position', () {
      for (var i = 0; i < ConditionRating.values.length; i++) {
        expect(ConditionRating.values[i].level, i + 1);
      }
    });

    test('fromStored maps each level back to its band', () {
      for (final rating in ConditionRating.values) {
        expect(ConditionRating.fromStored(rating.level), rating);
      }
    });

    test('fromStored returns null for a missing rating', () {
      expect(ConditionRating.fromStored(null), isNull);
    });

    test('fromStored rounds the decimal the column stores', () {
      // Condition.ConditionRating is DECIMAL(3,1).
      expect(ConditionRating.fromStored(3.0), ConditionRating.average);
      expect(ConditionRating.fromStored(4.4), ConditionRating.good);
    });

    test('fromStored clamps values outside the band range', () {
      expect(ConditionRating.fromStored(0), ConditionRating.toBeRemodeled);
      expect(ConditionRating.fromStored(-2), ConditionRating.toBeRemodeled);
      expect(ConditionRating.fromStored(9), ConditionRating.excellent);
    });
  });
}
