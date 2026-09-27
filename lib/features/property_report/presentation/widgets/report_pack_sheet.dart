import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../report_settings/data/models/report_settings.dart';
import '../../data/models/property_report.dart';

/// What the agent decides before the pack is made.
class PackOptions {
  final String preparedFor;
  final String greeting;
  final double low;
  final double high;
  final double listingPrice;
  final CalculatorDefaults calculator;

  const PackOptions({
    required this.preparedFor,
    required this.greeting,
    required this.low,
    required this.high,
    required this.listingPrice,
    required this.calculator,
  });
}

/// Asks for the owners' names, the agent's final range and listing price, and
/// this report's calculator figures (prefilled from Report settings).
Future<PackOptions?> showReportPackSheet({
  required BuildContext context,
  required RealEstateTheme theme,
  required PackOptions initial,
}) => showRealEstateBottomSheet<PackOptions>(
  context: context,
  theme: theme,
  builder: (_) => _ReportPackSheet(theme: theme, initial: initial),
);

class _ReportPackSheet extends StatefulWidget {
  final RealEstateTheme theme;
  final PackOptions initial;

  const _ReportPackSheet({required this.theme, required this.initial});

  @override
  State<_ReportPackSheet> createState() => _ReportPackSheetState();
}

class _ReportPackSheetState extends State<_ReportPackSheet> {
  late final Map<String, TextEditingController> _c;
  late bool _vat;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final calc = i.calculator;
    String n(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    _c = {
      'preparedFor': TextEditingController(text: i.preparedFor),
      'greeting': TextEditingController(text: i.greeting),
      'low': TextEditingController(text: n(i.low)),
      'high': TextEditingController(text: n(i.high)),
      'listing': TextEditingController(text: n(i.listingPrice)),
      'early': TextEditingController(text: n(calc.commissionEarlyPercent)),
      'late': TextEditingController(text: n(calc.commissionLatePercent)),
      'rate': TextEditingController(text: n(calc.interestRatePercent)),
      'term': TextEditingController(text: '${calc.bondTermYears}'),
      'deposit': TextEditingController(text: n(calc.depositPercent)),
    };
    _vat = calc.commissionIncludesVat;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String key) =>
      double.tryParse(_c[key]!.text.replaceAll(RegExp(r'[\s,R]'), ''));

  void _create() {
    final low = _num('low');
    final high = _num('high');
    final listing = _num('listing');
    if (low == null ||
        high == null ||
        listing == null ||
        low <= 0 ||
        high < low) {
      setState(
        () => _error = 'Enter your range (low to high) and the listing price.',
      );
      return;
    }
    final calc = widget.initial.calculator;
    Navigator.of(context).pop(
      PackOptions(
        preparedFor: _c['preparedFor']!.text.trim(),
        greeting: _c['greeting']!.text.trim(),
        low: low,
        high: high,
        listingPrice: listing,
        calculator: calc.copyWith(
          commissionEarlyPercent: _num('early') ?? calc.commissionEarlyPercent,
          commissionLatePercent: _num('late') ?? calc.commissionLatePercent,
          interestRatePercent: _num('rate') ?? calc.interestRatePercent,
          bondTermYears: (_num('term') ?? calc.bondTermYears.toDouble())
              .round(),
          depositPercent: _num('deposit') ?? calc.depositPercent,
          commissionIncludesVat: _vat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))];
    Widget field(
      String key,
      String label, {
      String? suffix,
      bool money = false,
      TextInputType? type,
    }) => CustomTextInput(
      theme: theme,
      label: label,
      controller: _c[key],
      keyboardType:
          type ?? const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: type == null ? digits : null,
      prefixIcon: money
          ? const Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Center(widthFactor: 1, child: Text('R')),
            )
          : null,
      suffixIcon: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(widthFactor: 1, child: Text(suffix)),
            ),
    );
    const gap = SizedBox(height: 12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Text(
                'Report pack',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cover, your profile, the valuation, area details, homes on the '
                'market, your letter, costs and your agency pages, in one PDF.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              field('preparedFor', 'Prepared for', type: TextInputType.name),
              gap,
              field(
                'greeting',
                'Letter greeting (Dear …)',
                type: TextInputType.name,
              ),
              gap,
              Text(
                'Your valuation',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              gap,
              Row(
                children: [
                  Expanded(child: field('low', 'From', money: true)),
                  const SizedBox(width: 12),
                  Expanded(child: field('high', 'To', money: true)),
                ],
              ),
              gap,
              field('listing', 'Recommended listing price', money: true),
              gap,
              Text(
                'Costs page',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              gap,
              Row(
                children: [
                  Expanded(
                    child: field(
                      'early',
                      'Commission, quick sale',
                      suffix: '%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field('late', 'Commission after', suffix: '%'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add VAT to commission'),
                value: _vat,
                onChanged: (v) => setState(() => _vat = v),
              ),
              Row(
                children: [
                  Expanded(child: field('rate', 'Interest rate', suffix: '%')),
                  const SizedBox(width: 12),
                  Expanded(child: field('term', 'Term', suffix: 'years')),
                ],
              ),
              gap,
              field('deposit', "Buyer's deposit", suffix: '%'),
              if (_error != null) ...[
                gap,
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(color: theme.error),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: CustomButton(
              text: 'Create report pack',
              fullWidth: true,
              theme: theme,
              onTap: _create,
            ),
          ),
        ),
      ],
    );
  }
}

/// The range to start from: the agent's own valuation when captured, else the
/// report's range, rounded to R10 000.
PackOptions initialPackOptions({
  required PropertyReport report,
  required String preparedFor,
  required String greeting,
  required double? agentValuation,
  required double? listingCommissionPercent,
  required CalculatorDefaults calculator,
}) {
  double r(double v) => (v / 10000).round() * 10000;
  final range = report.bestRange;
  final mid = agentValuation ?? range?.mid ?? report.municipalValueZar ?? 0;
  final low = r(range?.low ?? mid * 0.95);
  final high = r(agentValuation ?? range?.high ?? mid * 1.05);
  return PackOptions(
    preparedFor: preparedFor,
    greeting: greeting,
    low: low,
    high: high < low ? low : high,
    listingPrice: r(high * 1.05),
    calculator: listingCommissionPercent == null
        ? calculator
        : calculator.copyWith(commissionEarlyPercent: listingCommissionPercent),
  );
}
