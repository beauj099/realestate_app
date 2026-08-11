import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/wizard_scaffold.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_actions.dart';

class AddressStep extends ConsumerWidget {
  const AddressStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return WizardScaffold(
      title: 'Where is the property?',
      description: 'Enter the property address details.',
      onBack: () => goBackWizard(context, ref),
      onNext: () => advanceWizard(context, ref),
      children: [
        Text(
          'Street Address',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          theme: theme,
          backgroundColor: theme.borderLight.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Street Number',
                      placeholder: '124',
                      initialValue: state.streetNumber,
                      onChanged: (val) =>
                          viewModel.updateAddress(streetNumber: val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Street Name',
                      placeholder: 'Some Street',
                      initialValue: state.street,
                      onChanged: (val) =>
                          viewModel.updateAddress(street: val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextInput(
                theme: theme,
                label: 'Unit Number (Optional)',
                placeholder: 'e.g. 5A, Flat 12',
                initialValue: state.unitNumber,
                onChanged: (val) =>
                    viewModel.updateAddress(unitNumber: val),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Suburb / District',
                      placeholder: 'Strand',
                      initialValue: state.suburb,
                      onChanged: (val) =>
                          viewModel.updateAddress(suburb: val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextInput(
                      theme: theme,
                      label: 'City',
                      placeholder: 'Cape Town',
                      initialValue: state.city,
                      onChanged: (val) =>
                          viewModel.updateAddress(city: val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Province / State',
                      placeholder: 'Western Cape',
                      initialValue: state.province,
                      onChanged: (val) =>
                          viewModel.updateAddress(province: val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Country',
                      placeholder: 'South Africa',
                      initialValue: state.country,
                      onChanged: (val) =>
                          viewModel.updateAddress(country: val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextInput(
                theme: theme,
                label: 'Postal Code',
                placeholder: '7140',
                initialValue: state.postalCode,
                onChanged: (val) =>
                    viewModel.updateAddress(postalCode: val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Additional Identifiers',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          theme: theme,
          backgroundColor: theme.borderLight.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextInput(
                theme: theme,
                label: 'Estate Name (Optional)',
                placeholder: 'e.g. Skyline Towers',
                initialValue: state.estateName,
                onChanged: (val) =>
                    viewModel.updateIdentifiers(estateName: val),
              ),
              const SizedBox(height: 16),
              CustomTextInput(
                theme: theme,
                label: 'Erf Number',
                placeholder: 'Enter registration number',
                initialValue: state.erfNumber,
                subtext: 'Found on municipal rates bill or property deed.',
                onChanged: (val) =>
                    viewModel.updateIdentifiers(erfNumber: val),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
