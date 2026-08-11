import '../data/models/enums/property_wizard_step.dart';
import '../data/models/property_state.dart';

extension WizardStepActions on PropertyState {
  PropertyState withStep(int step) => copyWith(currentStep: step);

  PropertyState withNextStep() {
    if (currentStep < PropertyWizardStep.values.length) {
      return copyWith(currentStep: currentStep + 1);
    }
    return this;
  }

  PropertyState withPrevStep() {
    if (currentStep > 1) {
      return copyWith(currentStep: currentStep - 1);
    }
    return this;
  }
}
