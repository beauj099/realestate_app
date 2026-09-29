import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/listing_photo.dart';
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

  /// Why the agent's range differs from the recorded sales' (for the letter).
  final String adjustmentReason;
  final CalculatorDefaults calculator;

  /// The cover's main photo and the row of up to three under it (photo
  /// paths or URLs from the listing).
  final String? coverPhoto;
  final List<String> gallery;

  const PackOptions({
    required this.preparedFor,
    required this.greeting,
    required this.low,
    required this.high,
    required this.listingPrice,
    this.adjustmentReason = '',
    required this.calculator,
    this.coverPhoto,
    this.gallery = const [],
  });
}

/// Asks for the owners' names, the agent's final range and listing price, and
/// this report's calculator figures (prefilled from Report settings).
///
/// [photos] are every photo of the listing (outside first, then the rooms'),
/// to choose the cover photo and the three under it from.
Future<PackOptions?> showReportPackSheet({
  required BuildContext context,
  required RealEstateTheme theme,
  required PackOptions initial,
  List<String> photos = const [],
  String baseUrl = '',
}) => showRealEstateBottomSheet<PackOptions>(
  context: context,
  theme: theme,
  builder: (_) => _ReportPackSheet(
    theme: theme,
    initial: initial,
    photos: photos,
    baseUrl: baseUrl,
  ),
);

class _ReportPackSheet extends StatefulWidget {
  final RealEstateTheme theme;
  final PackOptions initial;
  final List<String> photos;
  final String baseUrl;

  const _ReportPackSheet({
    required this.theme,
    required this.initial,
    this.photos = const [],
    this.baseUrl = '',
  });

  @override
  State<_ReportPackSheet> createState() => _ReportPackSheetState();
}

class _ReportPackSheetState extends State<_ReportPackSheet> {
  late final Map<String, TextEditingController> _c;
  late bool _vat;
  String? _error;

  /// The listing price is suggested, but goes out under the agent's name, so
  /// they tick it off before the pack is made.
  bool _priceConfirmed = false;

  /// Picked in order: the first is the cover, the next three the row.
  late final List<String> _picked;
  static const _maxPicked = 4;

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
      'reason': TextEditingController(text: i.adjustmentReason),
      'early': TextEditingController(text: n(calc.commissionEarlyPercent)),
      'late': TextEditingController(text: n(calc.commissionLatePercent)),
      'rate': TextEditingController(text: n(calc.interestRatePercent)),
      'term': TextEditingController(text: '${calc.bondTermYears}'),
      'deposit': TextEditingController(text: n(calc.depositPercent)),
    };
    _vat = calc.commissionIncludesVat;
    _picked = [
      ?i.coverPhoto,
      ...i.gallery.where((g) => g != i.coverPhoto),
    ].where(widget.photos.contains).take(_maxPicked).toList();
  }

  void _togglePhoto(String photo) => setState(() {
    if (!_picked.remove(photo) && _picked.length < _maxPicked) {
      _picked.add(photo);
    }
  });

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
    if (!_priceConfirmed) {
      setState(() => _error = 'Confirm the recommended listing price first.');
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
        adjustmentReason: _c['reason']!.text.trim(),
        coverPhoto: _picked.firstOrNull,
        gallery: _picked.skip(1).toList(),
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
              if (widget.photos.isNotEmpty) ...[
                gap,
                Text(
                  'Cover photos',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap the main photo first, then up to three for the row '
                  'under it. Tap again to take one out.',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _photoGrid(theme, textTheme),
              ],
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
              field(
                'reason',
                'If your range differs from the sales: why?',
                type: TextInputType.text,
              ),
              const SizedBox(height: 4),
              Text(
                'For example "the pool, the flatlet and its condition". The '
                'letter gives the sales\' own range next to yours and this '
                'reason, so the two never disagree unexplained.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Suggested: the top of the range plus 5%, to leave room for '
                'negotiation. The letter gives it as your recommendation.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _priceConfirmed,
                onChanged: (v) => setState(() {
                  _priceConfirmed = v ?? false;
                  if (_priceConfirmed) _error = null;
                }),
                title: Text(
                  'I have checked this range and listing price',
                  style: textTheme.bodyMedium,
                ),
              ),
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

extension on _ReportPackSheetState {
  Widget _photoGrid(RealEstateTheme theme, TextTheme textTheme) =>
      GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final photo in widget.photos)
            GestureDetector(
              onTap: () => _togglePhoto(photo),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: listingPhoto(
                      photo,
                      theme: theme,
                      textTheme: textTheme,
                      cacheWidth: 240,
                      baseUrl: widget.baseUrl,
                    ),
                  ),
                  if (_picked.indexOf(photo) case final i when i >= 0) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.primaryColor, width: 3),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          i == 0 ? 'Main' : '$i',
                          style: TextStyle(
                            color: theme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
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
  String? coverPhoto,
  List<String> gallery = const [],
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
    coverPhoto: coverPhoto,
    gallery: gallery,
    calculator: listingCommissionPercent == null
        ? calculator
        : calculator.copyWith(commissionEarlyPercent: listingCommissionPercent),
  );
}
