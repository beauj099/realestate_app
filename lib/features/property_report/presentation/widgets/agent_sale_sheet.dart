import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/agent_sales.dart';
import '../../data/models/property_report.dart';

/// Asks for a sale the agent knows about in the report's suburb. Returns the
/// sale to log, or null when the agent closes the sheet.
Future<NewAgentSale?> showAgentSaleSheet({
  required BuildContext context,
  required RealEstateTheme theme,
  required PropertyReport report,
}) => showRealEstateBottomSheet<NewAgentSale>(
  context: context,
  theme: theme,
  builder: (_) => _AgentSaleSheet(theme: theme, report: report),
);

class _AgentSaleSheet extends StatefulWidget {
  final RealEstateTheme theme;
  final PropertyReport report;

  const _AgentSaleSheet({required this.theme, required this.report});

  @override
  State<_AgentSaleSheet> createState() => _AgentSaleSheetState();
}

class _AgentSaleSheetState extends State<_AgentSaleSheet> {
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _floor = TextEditingController();
  final _erf = TextEditingController();
  final _bedrooms = TextEditingController();
  final _bathrooms = TextEditingController();
  final _notes = TextEditingController();
  bool? _pool;
  DateTime? _saleDate;
  EvidenceLevel? _evidence;
  SaleCondition? _condition;
  bool _tried = false;

  @override
  void dispose() {
    for (final c in [
      _address,
      _price,
      _floor,
      _erf,
      _bedrooms,
      _bathrooms,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _priceValue => double.tryParse(_price.text);

  String? get _addressError =>
      _tried && _address.text.trim().isEmpty ? 'Enter the address' : null;

  String? get _priceError => _tried && (_priceValue ?? 0) < 10000
      ? 'Enter the sale price in rand'
      : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate ?? now,
      firstDate: DateTime(now.year - 5, now.month, now.day),
      lastDate: now,
      helpText: 'When was it sold?',
    );
    if (picked != null) setState(() => _saleDate = picked);
  }

  void _save() {
    setState(() => _tried = true);
    if (_addressError != null ||
        _priceError != null ||
        _saleDate == null ||
        _evidence == null) {
      return;
    }
    Navigator.of(context).pop(
      NewAgentSale(
        municipality: widget.report.municipality,
        suburb: widget.report.suburb,
        address: _address.text,
        saleDate: _saleDate!,
        salePriceZar: _priceValue!,
        evidence: _evidence!,
        floorM2: double.tryParse(_floor.text),
        erfM2: double.tryParse(_erf.text),
        bedrooms: int.tryParse(_bedrooms.text),
        bathrooms: int.tryParse(_bathrooms.text),
        hasPool: _pool,
        condition: _condition,
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final suburb = titleCase(widget.report.suburb);
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    const gap = SizedBox(height: 14);

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Text(
                'Log a sale in $suburb',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shared with agents who report on $suburb, so everyone '
                'values with the latest prices. Your name is never shown.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              CustomTextInput(
                theme: theme,
                label: 'Address',
                placeholder: 'e.g. 12 Oak Avenue',
                controller: _address,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                errorText: _addressError,
                isRequired: true,
                onChanged: (_) => setState(() {}),
              ),
              gap,
              // Sales data is South African only, so the price is in rand
              // whatever currency the agent picked in Settings.
              CustomTextInput(
                theme: theme,
                label: 'Sale price',
                placeholder: 'e.g. 2500000',
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                prefixIcon: CurrencyPrefix(symbol: 'R', theme: theme),
                errorText: _priceError,
                subtext: _priceValue == null ? null : rand(_priceValue!),
                isRequired: true,
                onChanged: (_) => setState(() {}),
              ),
              gap,
              _DateField(
                theme: theme,
                date: _saleDate,
                error: _tried && _saleDate == null,
                onTap: _pickDate,
              ),
              const SizedBox(height: 18),
              label('How do you know?'),
              for (final e in EvidenceLevel.capturable)
                _EvidenceTile(
                  theme: theme,
                  evidence: e,
                  selected: _evidence == e,
                  onTap: () => setState(() => _evidence = e),
                ),
              if (_tried && _evidence == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Choose how you know about this sale',
                    style: textTheme.bodySmall?.copyWith(color: theme.error),
                  ),
                ),
              const SizedBox(height: 18),
              label('The property (if you know)'),
              Row(
                children: [
                  Expanded(
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Floor size (m²)',
                      controller: _floor,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextInput(
                      theme: theme,
                      label: 'Erf size (m²)',
                      controller: _erf,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly,
                    ),
                  ),
                ],
              ),
              gap,
              Row(
                children: [
                  for (final (i, (name, controller)) in [
                    ('Bedrooms', _bedrooms),
                    ('Bathrooms', _bathrooms),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextInput(
                        theme: theme,
                        label: name,
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              gap,
              Wrap(
                spacing: 8,
                children: [
                  for (final (value, text) in [
                    (true, 'Pool'),
                    (false, 'No pool'),
                  ])
                    ChoiceChip(
                      label: Text(text),
                      selected: _pool == value,
                      selectedColor: theme.primaryColor.withValues(alpha: 0.15),
                      onSelected: (on) =>
                          setState(() => _pool = on ? value : null),
                    ),
                ],
              ),
              gap,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in SaleCondition.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _condition == c,
                      selectedColor: theme.primaryColor.withValues(alpha: 0.15),
                      onSelected: (on) =>
                          setState(() => _condition = on ? c : null),
                    ),
                ],
              ),
              gap,
              CustomTextInput(
                theme: theme,
                label: 'Notes',
                placeholder: 'e.g. Sold with a new kitchen, 3 weeks on market',
                controller: _notes,
                maxLines: 3,
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: CustomButton(
              text: 'Save sale',
              fullWidth: true,
              theme: theme,
              onTap: _save,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final RealEstateTheme theme;
  final DateTime? date;
  final bool error;
  final VoidCallback onTap;

  const _DateField({
    required this.theme,
    required this.date,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error ? theme.error : theme.borderLight),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: theme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null
                    ? 'When was it sold? *'
                    : 'Sold ${DateFormat('d MMMM yyyy').format(date!)}',
                style: textTheme.bodyLarge?.copyWith(
                  color: date == null ? theme.textSecondary : theme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final RealEstateTheme theme;
  final EvidenceLevel evidence;
  final bool selected;
  final VoidCallback onTap;

  const _EvidenceTile({
    required this.theme,
    required this.evidence,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? theme.primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: selected ? theme.primaryColor : theme.borderLight,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? theme.primaryColor : theme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      evidence.weightHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
