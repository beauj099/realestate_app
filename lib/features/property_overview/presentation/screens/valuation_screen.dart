import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../property_report/data/models/property_report.dart';
import '../../../property_report/providers/property_report_provider.dart';
import '../../../property_report/providers/report_preparer.dart';
import '../../../report_settings/providers/report_settings_provider.dart';
import '../../data/models/listing_valuation.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_section_scaffold.dart';

/// Price & Commission: every figure the report pack uses, in one place.
///
/// Filled in after the report: the agent's range and asking price start from
/// the report's range (once there is one), commission and the buyer's bond
/// from Report settings. The pack sheet reads them from here and writes back
/// what the agent settles on there, so changing a figure and making the pack
/// again is all a new report needs.
class ValuationScreen extends ConsumerStatefulWidget {
  const ValuationScreen({super.key});

  @override
  ConsumerState<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends ConsumerState<ValuationScreen> {
  PropertyReport? _report;

  /// Rebuilds the fields after they are filled in for the agent.
  int _version = 0;
  bool _filledFromReport = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final report = await savedReportFor(
      ref.read(reportCacheProvider),
      ref.read(propertyViewModelProvider),
    );
    if (!mounted || report == null) return;
    setState(() => _report = report);
    // Nothing of the agent's own yet: start from the report.
    final v = ref.read(propertyViewModelProvider).listingValuation;
    if (v.valueLow.isEmpty && v.valueHigh.isEmpty && v.listingPrice.isEmpty) {
      _useReportRange();
    }
  }

  /// The report's range, rounded to R10 000, and an asking price 5% above
  /// its top.
  void _useReportRange() {
    final range = _report?.bestRange;
    final low = range?.low, high = range?.high;
    if (low == null || high == null) return;
    int r(double v) => (v / 10000).round() * 10000;
    ref
        .read(propertyViewModelProvider.notifier)
        .editValuation(
          (v) => v.copyWith(
            valueLow: '${r(low)}',
            valueHigh: '${r(high)}',
            listingPrice: '${r(high * 1.05)}',
          ),
        );
    setState(() {
      _version++;
      _filledFromReport = true;
    });
  }

  Future<String?> _save() async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    // The single figure older screens and the home cards read: the middle
    // of the range.
    viewModel.editValuation((v) {
      final low = double.tryParse(v.valueLow);
      final high = double.tryParse(v.valueHigh);
      if (low == null || high == null) return v;
      return v.copyWith(
        agentValuation: '${(((low + high) / 2) / 10000).round() * 10000}',
      );
    });
    await viewModel.saveValuation();
    final error = ref.read(propertyViewModelProvider).errorMessage;
    return error == null ? null : friendlySaveMessage(error, 'valuation');
  }

  String? _validate() {
    final v = ref.read(propertyViewModelProvider).listingValuation;
    for (final pct in [v.commissionPercent, v.commissionLatePercent]) {
      final n = double.tryParse(pct.trim());
      if (n != null && (n < 0 || n > 100)) {
        return 'Commission must be between 0 and 100%.';
      }
    }
    final low = double.tryParse(v.valueLow.trim());
    final high = double.tryParse(v.valueHigh.trim());
    if (low != null && high != null && high < low) {
      return 'The top of your range is below the bottom.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyViewModelProvider);
    final v = state.listingValuation;
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final currency = ref.watch(regionProvider).currencySymbol;
    final textTheme = theme.toThemeData().textTheme;
    final defaults = ref.watch(reportSettingsProvider).calculator;

    void edit(ListingValuation Function(ListingValuation v) change) =>
        viewModel.editValuation(change);
    String n(num x) =>
        x == x.roundToDouble() ? x.round().toString() : x.toString();
    final decimals = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
    ];
    final digits = [FilteringTextInputFormatter.digitsOnly];
    const money = TextInputType.numberWithOptions(decimal: true);
    const gap = SizedBox(height: 14);
    Widget prefix() => CurrencyPrefix(symbol: currency, theme: theme);

    final netPrice = double.tryParse(v.ownersNetPrice.trim());
    final commission =
        double.tryParse(v.commissionPercent.trim()) ??
        defaults.commissionEarlyPercent;
    final range = _report?.bestRange;

    return WizardSectionScaffold(
      title: 'Price & Commission',
      sectionName: 'price and commission',
      validate: _validate,
      onSave: _save,
      child: Column(
        key: ValueKey('valuation_$_version'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Every figure in the report pack. Change one and make the pack '
            'again; nothing else needs redoing.',
            style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (range?.low != null && range?.high != null)
            _ReportRangeCard(
              text:
                  '${_report!.rangeFromAgentSales ? 'Agent-reported sales' : 'Recorded sales'} '
                  'suggest ${rand(range!.low!)} – ${rand(range.high!)}.',
              filled: _filledFromReport,
              theme: theme,
              textTheme: textTheme,
              onUse: _useReportRange,
            )
          else
            _ReportRangeCard(
              text:
                  'Make the valuation report first: your range then starts '
                  'from the sales it finds.',
              filled: false,
              theme: theme,
              textTheme: textTheme,
            ),
          const SizedBox(height: 20),
          _Heading('Your valuation', theme: theme, textTheme: textTheme),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'From',
                  prefixIcon: prefix(),
                  initialValue: v.valueLow,
                  keyboardType: money,
                  inputFormatters: decimals,
                  onChanged: (x) => edit((v) => v.copyWith(valueLow: x)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'To',
                  prefixIcon: prefix(),
                  initialValue: v.valueHigh,
                  keyboardType: money,
                  inputFormatters: decimals,
                  onChanged: (x) => edit((v) => v.copyWith(valueHigh: x)),
                ),
              ),
            ],
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Asking price',
            prefixIcon: prefix(),
            initialValue: v.listingPrice,
            keyboardType: money,
            inputFormatters: decimals,
            onChanged: (x) => edit((v) => v.copyWith(listingPrice: x)),
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Why your range differs from the sales (optional)',
            placeholder: 'e.g. the pool, the flatlet and its condition',
            subtext:
                'The letter gives it when your range is more than 5% from '
                "the sales'.",
            initialValue: v.adjustmentReason,
            maxLines: 3,
            onChanged: (x) => edit((v) => v.copyWith(adjustmentReason: x)),
          ),
          const SizedBox(height: 24),
          _Heading('Owner and commission', theme: theme, textTheme: textTheme),
          CustomTextInput(
            theme: theme,
            label: "Owner's net price",
            prefixIcon: prefix(),
            initialValue: v.ownersNetPrice,
            keyboardType: money,
            inputFormatters: decimals,
            onChanged: (x) => edit((v) => v.copyWith(ownersNetPrice: x)),
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'Commission %',
                  placeholder: n(defaults.commissionEarlyPercent),
                  initialValue: v.commissionPercent,
                  keyboardType: money,
                  inputFormatters: decimals,
                  onChanged: (x) =>
                      edit((v) => v.copyWith(commissionPercent: x)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'If sold within (months)',
                  placeholder: '${defaults.earlyMonths}',
                  initialValue: v.commissionEarlyMonths,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  onChanged: (x) =>
                      edit((v) => v.copyWith(commissionEarlyMonths: x)),
                ),
              ),
            ],
          ),
          gap,
          CustomTextInput(
            theme: theme,
            label: 'Commission % after that',
            placeholder: n(defaults.commissionLatePercent),
            initialValue: v.commissionLatePercent,
            keyboardType: money,
            inputFormatters: decimals,
            onChanged: (x) => edit((v) => v.copyWith(commissionLatePercent: x)),
          ),
          _Note(
            'Empty: your Report settings, ${n(defaults.commissionEarlyPercent)}% '
            'within ${defaults.earlyMonths} months, then '
            '${n(defaults.commissionLatePercent)}%.',
            theme: theme,
            textTheme: textTheme,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add VAT to the commission'),
            value: v.commissionIncludesVat ?? defaults.commissionIncludesVat,
            onChanged: (on) =>
                edit((v) => v.copyWith(commissionIncludesVat: on)),
          ),
          if (netPrice != null && commission > 0) ...[
            const SizedBox(height: 8),
            _CommissionSummary(
              netPrice: netPrice,
              commissionPercent: commission,
              currencySymbol: currency,
              theme: theme,
              textTheme: textTheme,
            ),
          ],
          const SizedBox(height: 24),
          _Heading(
            "Buyer's bond (costs page)",
            theme: theme,
            textTheme: textTheme,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'Interest %',
                  placeholder: n(defaults.interestRatePercent),
                  initialValue: v.interestRatePercent,
                  keyboardType: money,
                  inputFormatters: decimals,
                  onChanged: (x) =>
                      edit((v) => v.copyWith(interestRatePercent: x)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'Years',
                  placeholder: '${defaults.bondTermYears}',
                  initialValue: v.bondTermYears,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  onChanged: (x) => edit((v) => v.copyWith(bondTermYears: x)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextInput(
                  theme: theme,
                  label: 'Deposit %',
                  placeholder: n(defaults.depositPercent),
                  initialValue: v.depositPercent,
                  keyboardType: money,
                  inputFormatters: decimals,
                  onChanged: (x) => edit((v) => v.copyWith(depositPercent: x)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Note(
            'Empty: your Report settings, ${n(defaults.interestRatePercent)}% '
            'over ${defaults.bondTermYears} years, '
            '${n(defaults.depositPercent)}% deposit.',
            theme: theme,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _Note(this.text, {required this.theme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _Heading(this.text, {required this.theme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textPrimary,
        ),
      ),
    );
  }
}

/// What the report suggests, with a button to start from it.
class _ReportRangeCard extends StatelessWidget {
  final String text;
  final bool filled;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback? onUse;

  const _ReportRangeCard({
    required this.text,
    required this.filled,
    required this.theme,
    required this.textTheme,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.query_stats_rounded, color: theme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filled ? '$text Filled in below; check it and save.' : text,
              style: textTheme.bodyMedium?.copyWith(color: theme.textPrimary),
            ),
          ),
          if (onUse != null && !filled)
            TextButton(onPressed: onUse, child: const Text('Use it')),
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
  final RealEstateTheme theme;
  final TextTheme textTheme;

  final String currencySymbol;

  const _CommissionSummary({
    required this.netPrice,
    required this.commissionPercent,
    required this.currencySymbol,
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
    return '$currencySymbol $buffer';
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
