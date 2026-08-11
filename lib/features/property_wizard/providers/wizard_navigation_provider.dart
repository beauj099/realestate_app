import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/enums/property_wizard_step.dart';
import '../data/models/property_state.dart';
import 'property_provider.dart';

class WizardNavigationData {
  final String headerTitle;
  final String progressLabel;
  final String stepTitle;
  final bool canGoNext;
  final PropertyWizardStep currentStep;

  WizardNavigationData({
    required this.headerTitle,
    required this.progressLabel,
    required this.stepTitle,
    required this.canGoNext,
    required this.currentStep,
  });

  factory WizardNavigationData.fromState(PropertyState state) {
    final step = PropertyWizardStep.fromStepNumber(state.currentStep);
    final isEditingRoom = state.selectedRoomId != null;

    return WizardNavigationData(
      headerTitle: isEditingRoom ? 'Property Details' : step.headerTitle,
      progressLabel: isEditingRoom
          ? ''
          : 'Step ${step.stepNumber} of ${PropertyWizardStep.values.length}',
      stepTitle: step.title,
      canGoNext: _isStepValid(state, step),
      currentStep: step,
    );
  }

  static bool _isStepValid(PropertyState state, PropertyWizardStep step) {
    switch (step) {
      case PropertyWizardStep.propertyType:
        return state.propertyTypeId > 0;
      case PropertyWizardStep.address:
        return state.street.isNotEmpty && state.city.isNotEmpty;
      case PropertyWizardStep.buildingInfo:
        return true;
      case PropertyWizardStep.propertyFeatures:
        return state.rooms.isNotEmpty;
      case PropertyWizardStep.valuationCosts:
        return state.listingValuation.ownersNetPrice.isNotEmpty;
      case PropertyWizardStep.contacts:
        return state.primaryContact.fullName.isNotEmpty;
      case PropertyWizardStep.review:
        return true;
    }
  }
}

final wizardNavigationProvider = Provider.autoDispose<WizardNavigationData>((ref) {
  final state = ref.watch(propertyViewModelProvider);
  return WizardNavigationData.fromState(state);
});
