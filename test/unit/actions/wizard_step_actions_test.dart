import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/features/property_wizard/actions/wizard_step_actions.dart';
import 'package:realestate_app/features/property_wizard/data/models/property_state.dart';

void main() {
  group('WizardStepActions', () {
    test('withStep sets the current step', () {
      final state = PropertyState();

      final updated = state.withStep(3);

      expect(updated.currentStep, 3);
    });

    test('withNextStep advances by one', () {
      final state = PropertyState(currentStep: 2);

      final updated = state.withNextStep();

      expect(updated.currentStep, 3);
    });

    test('withNextStep does not advance past last step', () {
      final state = PropertyState(currentStep: 7);

      final updated = state.withNextStep();

      expect(updated.currentStep, 7);
    });

    test('withPrevStep goes back by one', () {
      final state = PropertyState(currentStep: 5);

      final updated = state.withPrevStep();

      expect(updated.currentStep, 4);
    });

    test('withPrevStep does not go below 1', () {
      final state = PropertyState(currentStep: 1);

      final updated = state.withPrevStep();

      expect(updated.currentStep, 1);
    });
  });
}
