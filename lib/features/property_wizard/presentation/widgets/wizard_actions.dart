import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums/property_wizard_step.dart';
import '../../providers/property_provider.dart';

Future<void> advanceWizard(BuildContext context, WidgetRef ref) async {
  final viewModel = ref.read(propertyViewModelProvider.notifier);
  await viewModel.nextStep();
  final state = ref.read(propertyViewModelProvider);
  if (state.errorMessage != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return;
  }
  final step = PropertyWizardStep.fromStepNumber(
    ref.read(propertyViewModelProvider).currentStep,
  );
  if (context.mounted) {
    context.go(step.routePath);
  }
}

void goBackWizard(BuildContext context, WidgetRef ref) {
  final viewModel = ref.read(propertyViewModelProvider.notifier);
  viewModel.prevStep();
  context.pop();
}
