import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../../property_report/data/models/property_report.dart';
import '../../../property_report/providers/property_report_provider.dart';
import '../../../property_report/providers/report_preparer.dart';
import '../../data/models/listing_details.dart';
import '../../data/models/listing_valuation.dart';
import '../../providers/property_provider.dart';
import '../widgets/month_year_field.dart';
import '../widgets/wizard_section_scaffold.dart';

/// When and for how much the owners bought, and their bond.
///
/// The date and price start from the municipality's last registered sale
/// once the address is known (Cape Town, Johannesburg). The bond (bank and
/// amount) is the owners' own answer: it is in the Deeds Office record, which
/// only paid data services sell. Buyers' names are never taken from a
/// register; the owners are the ones on Owner Details.
class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen> {
  SaleRecord? _registered;
  int _version = 0;

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
    if (!mounted || report?.lastSale == null) return;
    setState(() => _registered = report!.lastSale);
  }

  void _useRegistered() {
    final sale = _registered;
    if (sale == null) return;
    ref
        .read(propertyViewModelProvider.notifier)
        .editValuation(
          (v) => v.copyWith(
            lastPurchaseDate: DateTime(sale.date.year, sale.date.month),
            lastPurchasePrice: sale.priceZar.round().toString(),
          ),
        );
    setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyViewModelProvider);
    final v = state.listingValuation;
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final currency = ref.watch(regionProvider).currencySymbol;
    final textTheme = theme.toThemeData().textTheme;
    final decimals = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
    ];
    const money = TextInputType.numberWithOptions(decimal: true);
    final sale = _registered;
    final matches =
        sale != null &&
        v.lastPurchaseDate?.year == sale.date.year &&
        v.lastPurchaseDate?.month == sale.date.month &&
        double.tryParse(v.lastPurchasePrice) == sale.priceZar.roundToDouble();

    return WizardSectionScaffold(
      title: 'Purchase History',
      sectionName: 'purchase history',
      onSave: () async {
        await viewModel.saveValuation();
        if (ref.read(propertyViewModelProvider).errorMessage == null) {
          await viewModel.saveDetails();
        }
        final error = ref.read(propertyViewModelProvider).errorMessage;
        return error == null
            ? null
            : friendlySaveMessage(error, 'purchase history');
      },
      child: Column(
        key: ValueKey('purchase_$_version'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When the owners bought, for how much, and their bond. The '
            'report shows it as their last purchase.',
            style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (sale != null)
            _RegisteredSale(
              text:
                  'Last registered sale: ${monthYear(sale.date)}, '
                  '${rand(sale.priceZar)}.',
              used: matches,
              theme: theme,
              textTheme: textTheme,
              onUse: _useRegistered,
            ),
          if (sale != null) const SizedBox(height: 16),
          MonthYearField(
            label: 'Bought in',
            helpText: 'When did the owners buy?',
            value: v.lastPurchaseDate,
            theme: theme,
            onChanged: (date) => date == null
                ? viewModel.editValuation(
                    (v) => v.copyWith(clearLastPurchaseDate: true),
                  )
                : viewModel.editValuation(
                    (v) => v.copyWith(lastPurchaseDate: date),
                  ),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Bought for',
            prefixIcon: CurrencyPrefix(symbol: currency, theme: theme),
            initialValue: v.lastPurchasePrice,
            keyboardType: money,
            inputFormatters: decimals,
            onChanged: (x) => viewModel.editValuation(
              (v) => v.copyWith(lastPurchasePrice: x),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Their bond',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask the owners. A bond to cancel affects their costs and '
            'timing.',
            style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: 12),
          _BankField(
            value: v.bondInstitution,
            theme: theme,
            onChanged: (bank) => viewModel.editValuation(
              (v) => v.copyWith(bondInstitution: bank),
            ),
          ),
          const SizedBox(height: 14),
          CustomTextInput(
            theme: theme,
            label: 'Bond amount',
            prefixIcon: CurrencyPrefix(symbol: currency, theme: theme),
            initialValue: v.bondAmount,
            keyboardType: money,
            inputFormatters: decimals,
            onChanged: (x) =>
                viewModel.editValuation((v) => v.copyWith(bondAmount: x)),
          ),
          const SizedBox(height: 24),
          Text(
            'Renovations since',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When, what it cost and what was done. Valuers and buyers ask; '
            'it explains a price above the area\'s sales.',
            style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: 10),
          for (final (i, r) in state.details.renovations.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: theme.cardBackgroundColor,
              child: ListTile(
                leading: Icon(
                  Icons.construction_outlined,
                  color: theme.primaryColor,
                ),
                title: Text(
                  [
                    if (r.year != null) '${r.year}',
                    if (r.amount.isNotEmpty) '$currency ${r.amount}',
                  ].join(' · '),
                ),
                subtitle: r.description.isEmpty ? null : Text(r.description),
                onTap: () => _editRenovation(context, i),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.delete_outline, color: theme.error),
                  onPressed: () => viewModel.editDetails(
                    (d) => d.copyWith(
                      renovations: [...d.renovations]..removeAt(i),
                    ),
                  ),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => _editRenovation(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add a renovation'),
          ),
        ],
      ),
    );
  }

  /// Adds a renovation ([index] null) or changes one.
  Future<void> _editRenovation(BuildContext context, int? index) async {
    final theme = ref.read(themeConfigProvider);
    final currency = ref.read(regionProvider).currencySymbol;
    final existing = index == null
        ? const Renovation()
        : ref.read(propertyViewModelProvider).details.renovations[index];
    final year = TextEditingController(text: existing.year?.toString() ?? '');
    final amount = TextEditingController(text: existing.amount);
    final what = TextEditingController(text: existing.description);
    final saved = await showDialog<Renovation>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(index == null ? 'Add a renovation' : 'Renovation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextInput(
              theme: theme,
              label: 'Year',
              controller: year,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextInput(
              theme: theme,
              label: 'Cost',
              controller: amount,
              prefixIcon: CurrencyPrefix(symbol: currency, theme: theme),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            CustomTextInput(
              theme: theme,
              label: 'What was done',
              placeholder: 'e.g. kitchen, both bathrooms, floors',
              controller: what,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialog,
              Renovation(
                year: int.tryParse(year.text),
                amount: amount.text.trim(),
                description: what.text.trim(),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    year.dispose();
    amount.dispose();
    what.dispose();
    if (saved == null ||
        (saved.year == null &&
            saved.amount.isEmpty &&
            saved.description.isEmpty)) {
      return;
    }
    ref
        .read(propertyViewModelProvider.notifier)
        .editDetails(
          (d) => d.copyWith(
            renovations: index == null
                ? [...d.renovations, saved]
                : [
                    for (final (i, r) in d.renovations.indexed)
                      i == index ? saved : r,
                  ],
          ),
        );
  }
}

class _RegisteredSale extends StatelessWidget {
  final String text;
  final bool used;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onUse;

  const _RegisteredSale({
    required this.text,
    required this.used,
    required this.theme,
    required this.textTheme,
    required this.onUse,
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
          Icon(Icons.gavel_rounded, color: theme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(color: theme.textPrimary),
            ),
          ),
          if (used)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.check, color: theme.completeColor),
            )
          else
            TextButton(onPressed: onUse, child: const Text('Use it')),
        ],
      ),
    );
  }
}

/// The bond's bank, "None" first.
class _BankField extends StatelessWidget {
  final String value;
  final RealEstateTheme theme;
  final ValueChanged<String> onChanged;

  const _BankField({
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    final banks = [
      ...bondInstitutions,
      if (value.isNotEmpty && !bondInstitutions.contains(value)) value,
    ];
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: theme.cardBackgroundColor,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.keyboard_arrow_down, color: theme.textSecondary),
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Bond with',
        filled: true,
        fillColor: theme.cardBackgroundColor,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: textTheme.bodyLarge?.copyWith(color: theme.textSecondary),
        border: border(theme.borderLight, 1),
        enabledBorder: border(theme.borderLight, 1),
        focusedBorder: border(theme.primaryColor, 2),
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(
            'No bond / not known',
            style: TextStyle(
              color: theme.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        for (final b in banks) DropdownMenuItem(value: b, child: Text(b)),
      ],
      onChanged: (b) => onChanged(b ?? ''),
    );
  }
}
