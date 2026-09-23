import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../providers/property_provider.dart';
import '../widgets/expense_documents_section.dart';
import '../widgets/wizard_section_scaffold.dart';

/// Monthly running costs for the property, and the accounts that back them.
///
/// Valuation (owner's net price, agent valuation, commission) used to sit here
/// but is a negotiated figure settled at the end rather than an expense, so it
/// moved to its own section — see `ValuationScreen`.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    List<TextInputFormatter> currencyOnly() => [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
    ];

    return WizardSectionScaffold(
      title: 'Expenses',
      sectionName: 'expenses',
      onSave: () async {
        await viewModel.saveRunningCosts();
        final error = ref.read(propertyViewModelProvider).errorMessage;
        return error == null ? null : friendlySaveMessage(error, 'expenses');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly running costs',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextInput(
            theme: theme,
            label: 'Monthly Levy (ZAR)',
            placeholder: 'e.g. 1500',
            initialValue: state.propertyRunningCosts.monthlyLevy,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateRunningCosts(monthlyLevy: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Monthly Rates (ZAR)',
            placeholder: 'e.g. 800',
            initialValue: state.propertyRunningCosts.monthlyRates,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateRunningCosts(monthlyRates: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Electricity (ZAR/month)',
            placeholder: 'e.g. 1200',
            initialValue: state.propertyRunningCosts.electricity,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateRunningCosts(electricity: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Water (ZAR/month)',
            placeholder: 'e.g. 400',
            initialValue: state.propertyRunningCosts.water,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateRunningCosts(water: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Sewage (ZAR/month)',
            placeholder: 'e.g. 350',
            initialValue: state.propertyRunningCosts.sewage,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateRunningCosts(sewage: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Refuse (ZAR/month)',
            placeholder: 'e.g. 250',
            initialValue: state.propertyRunningCosts.refuse,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateRunningCosts(refuse: val),
          ),
          const SizedBox(height: 32),
          ExpenseDocumentsSection(
            documents: state.documents,
            theme: theme,
            baseUrl: ref.watch(apiClientProvider).baseUrl,
            onAdd: viewModel.addDocument,
            onRemove: viewModel.removeDocument,
          ),
        ],
      ),
    );
  }
}
