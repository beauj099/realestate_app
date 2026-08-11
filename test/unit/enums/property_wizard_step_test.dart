import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/features/property_wizard/data/models/enums/property_wizard_step.dart';

void main() {
  group('PropertyWizardStep', () {
    test('has exactly 7 steps', () {
      expect(PropertyWizardStep.values.length, 7);
    });

    test('fromStepNumber returns correct step', () {
      expect(
        PropertyWizardStep.fromStepNumber(1),
        PropertyWizardStep.propertyType,
      );
      expect(
        PropertyWizardStep.fromStepNumber(4),
        PropertyWizardStep.propertyFeatures,
      );
      expect(PropertyWizardStep.fromStepNumber(7), PropertyWizardStep.review);
    });

    test('fromStepNumber throws for invalid step', () {
      expect(
        () => PropertyWizardStep.fromStepNumber(0),
        throwsA(isA<StateError>()),
      );
      expect(
        () => PropertyWizardStep.fromStepNumber(8),
        throwsA(isA<StateError>()),
      );
    });

    test('fromRoutePath returns correct step', () {
      expect(
        PropertyWizardStep.fromRoutePath('/wizard/property-type'),
        PropertyWizardStep.propertyType,
      );
      expect(
        PropertyWizardStep.fromRoutePath('/wizard/address'),
        PropertyWizardStep.address,
      );
      expect(
        PropertyWizardStep.fromRoutePath('/wizard/review'),
        PropertyWizardStep.review,
      );
    });

    test('step properties are correct', () {
      expect(PropertyWizardStep.propertyType.stepNumber, 1);
      expect(PropertyWizardStep.propertyType.title, 'Property Type');
      expect(
        PropertyWizardStep.propertyType.routePath,
        '/wizard/property-type',
      );

      expect(PropertyWizardStep.review.stepNumber, 7);
      expect(PropertyWizardStep.review.title, 'Review');
      expect(PropertyWizardStep.review.routePath, '/wizard/review');
    });
  });
}
