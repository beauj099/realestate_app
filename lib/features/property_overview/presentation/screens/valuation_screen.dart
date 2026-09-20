import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_section_scaffold.dart';

/// Pricing and commission — the last thing agreed before a listing is
/// submitted.
///
/// Deliberately separate from Expenses: running costs are facts about the
/// property captured on site, while valuation is a negotiated figure settled at
/// the end. Mixing them meant agents were asked for a price before they had
/// walked the house.
class ValuationScreen extends ConsumerWidget {
  const ValuationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    List<TextInputFormatter> currencyOnly() => [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
    ];

    final netPrice = double.tryParse(
      state.listingValuation.ownersNetPrice.trim(),
    );
    final commission = double.tryParse(
      state.listingValuation.commissionPercent.trim(),
    );

    return WizardSectionScaffold(
      title: 'Valuation',
      sectionName: 'valuation',
      validate: () {
        final pct = double.tryParse(
          state.listingValuation.commissionPercent.trim(),
        );
        if (pct != null && (pct < 0 || pct > 100)) {
          return 'Commission must be between 0 and 100%.';
        }
        return null;
      },
      onSave: () async {
        await viewModel.saveValuation();
        final error = ref.read(propertyViewModelProvider).errorMessage;
        return error == null
            ? null
            : friendlySaveMessage(error, 'valuation');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing and commission',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextInput(
            theme: theme,
            label: "Owner's Net Price (ZAR)",
            placeholder: 'e.g. 2500000',
            initialValue: state.listingValuation.ownersNetPrice,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateValuation(ownersNetPrice: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Agent Valuation (ZAR)',
            placeholder: 'e.g. 2750000',
            initialValue: state.listingValuation.agentValuation,
            keyboardType: TextInputType.number,
            inputFormatters: currencyOnly(),
            onChanged: (val) => viewModel.updateValuation(agentValuation: val),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Commission (%)',
            placeholder: 'e.g. 5',
            initialValue: state.listingValuation.commissionPercent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: currencyOnly(),
            onChanged: (val) =>
                viewModel.updateValuation(commissionPercent: val),
          ),
          if (netPrice != null && commission != null && commission > 0) ...[
            const SizedBox(height: 20),
            _CommissionSummary(
              netPrice: netPrice,
              commissionPercent: commission,
              theme: theme,
              textTheme: textTheme,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows what the commission percentage actually works out to.
///
/// Agents were doing this arithmetic on a phone calculator in front of the
/// owner; showing it live avoids that and catches a mistyped percentage.
class _CommissionSummary extends StatelessWidget {
  final double netPrice;
  final double commissionPercent;
  final dynamic theme;
  final TextTheme textTheme;

  const _CommissionSummary({
    required this.netPrice,
    required this.commissionPercent,
    required this.theme,
    required this.textTheme,
  });

  String _money(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(rounded[i]);
    }
    return 'R $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final commission = netPrice * commissionPercent / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.borderLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('Commission at $commissionPercent%', _money(commission)),
          const SizedBox(height: 8),
          _row('Gross asking price', _money(netPrice + commission), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
        ),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: theme.textPrimary,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
