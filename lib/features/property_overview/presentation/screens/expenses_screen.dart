import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../providers/property_provider.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _saveAndPop(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    await viewModel.saveValuation();
    if (!context.mounted) return;
    Navigator.pop(context);
    final error = ref.read(propertyViewModelProvider).errorMessage;
    if (error != null && context.mounted) {
      final theme = ref.read(themeConfigProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlySaveMessage(error, 'valuation')),
          backgroundColor: theme.error,
        ),
      );
    }
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndPop(context, ref);
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Expenses',
          onBack: () => Navigator.maybePop(context),
          theme: theme,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter the pricing and monthly expenses for this property.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'VALUATION',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textLabel,
                    fontSize: 13,
                    letterSpacing: 0.5,
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
                        label: "Owner's Net Price (ZAR)",
                        placeholder: 'e.g. 2500000',
                        initialValue: state.listingValuation.ownersNetPrice,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateValuation(ownersNetPrice: val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        theme: theme,
                        label: 'Agent Valuation (ZAR)',
                        placeholder: 'e.g. 2750000',
                        initialValue: state.listingValuation.agentValuation,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateValuation(agentValuation: val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        theme: theme,
                        label: 'Commission (%)',
                        placeholder: 'e.g. 5',
                        initialValue: state.listingValuation.commissionPercent,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateValuation(commissionPercent: val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'PROPERTY RUNNING COSTS',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textLabel,
                    fontSize: 13,
                    letterSpacing: 0.5,
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
                        label: 'Monthly Levy (ZAR)',
                        placeholder: 'e.g. 1500',
                        initialValue: state.propertyRunningCosts.monthlyLevy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateRunningCosts(monthlyLevy: val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        theme: theme,
                        label: 'Monthly Rates (ZAR)',
                        placeholder: 'e.g. 800',
                        initialValue: state.propertyRunningCosts.monthlyRates,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateRunningCosts(monthlyRates: val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        theme: theme,
                        label: 'Electricity (ZAR/month)',
                        placeholder: 'e.g. 1200',
                        initialValue: state.propertyRunningCosts.electricity,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateRunningCosts(electricity: val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        theme: theme,
                        label: 'Water (ZAR/month)',
                        placeholder: 'e.g. 400',
                        initialValue: state.propertyRunningCosts.water,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateRunningCosts(water: val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextInput(
                        theme: theme,
                        label: 'Municipal Account (ZAR/month)',
                        placeholder: 'e.g. 2500',
                        initialValue:
                            state.propertyRunningCosts.municipalAccount,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        onChanged: (val) =>
                            viewModel.updateRunningCosts(municipalAccount: val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Deprecated: use ExpensesScreen instead
typedef ListingValuationScreen = ExpensesScreen;
