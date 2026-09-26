import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/property_state.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/providers/city_records_autofill.dart';

// Live report for 17 Pine Road, Claremont (erf 53927): 1 085 m² erf, 300 m²
// dwelling, zoning GR2 (General Residential 2).
PropertyReport _report() => PropertyReport.fromJson(
  jsonDecode(
        File('test/fixtures/property_report_53927.json').readAsStringSync(),
      )
      as Map<String, dynamic>,
);

void main() {
  group('zoningIdFor', () {
    test('maps City codes onto the five zoning chips', () {
      expect(zoningIdFor('SR1', 'Single Residential 1'), 1);
      expect(zoningIdFor('GR2', 'General Residential 2'), 2);
      expect(zoningIdFor('GB5', 'General Business 5'), 3);
      expect(zoningIdFor('LB1', null), 3);
      expect(zoningIdFor('AG', 'Agricultural'), 4);
      expect(zoningIdFor('MU2', 'Mixed Use 2'), 5);
    });

    test('falls back to the description, and knows when it cannot map', () {
      expect(zoningIdFor(null, 'Residential 1 : Conventional Housing'), 1);
      expect(zoningIdFor('OS2', 'Open Space 2'), isNull);
      expect(zoningIdFor(null, null), isNull);
    });
  });

  group('planAutofill', () {
    test('fills every empty field from the report', () {
      final plan = planAutofill(PropertyState(), _report());
      expect(plan.erfNumber, '53927');
      expect(plan.erfSize, '1085');
      expect(plan.floorArea, '300');
      expect(plan.zoningId, 2);
      expect(plan.latitude, closeTo(-33.9897, 0.001));
      expect(plan.touchesAddress, isTrue);
      expect(plan.touchesBuildingInfo, isTrue);
      expect(plan.filled.join(' | '), contains('floor area 300'));
    });

    test('never overwrites what the agent entered', () {
      final plan = planAutofill(
        PropertyState(
          erfNumber: '99',
          erfSize: '1000',
          floorArea: '250',
          zoningId: 1,
          latitude: -33.9,
          longitude: 18.4,
        ),
        _report(),
      );
      expect(plan.filled, isEmpty);
      expect(plan.isEmpty, isTrue);
    });

    test('fills only the gaps', () {
      final plan = planAutofill(PropertyState(erfSize: '1100'), _report());
      expect(plan.erfSize, isNull, reason: 'the agent typed an erf size');
      expect(plan.floorArea, '300');
    });

    test('says when the floor area is only the roof footprint', () {
      final json =
          jsonDecode(
                File(
                  'test/fixtures/property_report_53927.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      json['dwellingExtentM2'] = null;
      final plan = planAutofill(PropertyState(), PropertyReport.fromJson(json));
      expect(plan.floorArea, '326');
      expect(plan.filled.join(' | '), contains('roof footprint'));
    });
  });
}
