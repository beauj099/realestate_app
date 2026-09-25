import 'package:flutter/material.dart';

import '../locale/countries.dart';
import '../theme/themes.dart';
import 'real_estate_dialog.dart';

/// What the country list is being used to choose.
enum CountryPickerMode {
  /// The agent's country: rows show the dialling code.
  country,

  /// The currency: rows show each country's currency.
  currency,
}

/// Opens the country list and returns the chosen country, or null.
///
/// South Africa is pinned first with a divider beneath it (bold when picking
/// a currency), then every other country alphabetically. Typing narrows the
/// list to countries whose name — or, for currencies, currency name or code —
/// contains the letters typed.
Future<Country?> showCountryPicker({
  required BuildContext context,
  required RealEstateTheme theme,
  required CountryPickerMode mode,
  Country? selected,
}) {
  return showRealEstateBottomSheet<Country>(
    context: context,
    theme: theme,
    builder: (_) =>
        _CountryPickerSheet(theme: theme, mode: mode, selected: selected),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final RealEstateTheme theme;
  final CountryPickerMode mode;
  final Country? selected;

  const _CountryPickerSheet({
    required this.theme,
    required this.mode,
    required this.selected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  bool get _isCurrency => widget.mode == CountryPickerMode.currency;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Country c) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (c.name.toLowerCase().contains(needle)) return true;
    if (_isCurrency) {
      return c.currencyName.toLowerCase().contains(needle) ||
          c.currencyCode.toLowerCase().contains(needle);
    }
    return c.dialPrefix.contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final ordered = Country.ordered;
    final pinned = ordered.first;
    final showPinned = _matches(pinned);
    final rest = ordered.skip(1).where(_matches).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isCurrency ? 'Currency' : 'Country',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                style: textTheme.bodyLarge?.copyWith(color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: _isCurrency
                      ? 'Type a country or currency…'
                      : 'Type your country…',
                  prefixIcon: Icon(Icons.search, color: theme.textSecondary),
                  isDense: true,
                  filled: true,
                  fillColor: theme.borderLight.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: !showPinned && rest.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'No country matches "${_query.trim()}".',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: rest.length + (showPinned ? 2 : 0),
                  itemBuilder: (context, i) {
                    if (showPinned && i == 0) return _row(pinned, textTheme);
                    if (showPinned && i == 1) {
                      return Divider(
                        height: 1,
                        thickness: _isCurrency ? 2.5 : 1,
                        color: _isCurrency
                            ? theme.textPrimary
                            : theme.borderLight,
                      );
                    }
                    return _row(rest[i - (showPinned ? 2 : 0)], textTheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _row(Country c, TextTheme textTheme) {
    final theme = widget.theme;
    final isSelected = c == widget.selected;
    return InkWell(
      onTap: () => Navigator.pop(context, c),
      child: Container(
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(c.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  if (_isCurrency)
                    Text(
                      c.currencyName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isCurrency ? c.currencySymbol : c.dialPrefix,
              style: textTheme.titleMedium?.copyWith(
                color: isSelected ? theme.primaryColor : theme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 20, color: theme.primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tappable field showing a country's flag and name (or, for a currency,
/// its symbol and name), opening [showCountryPicker].
class CountryField extends StatelessWidget {
  final Country country;
  final String label;
  final CountryPickerMode mode;
  final VoidCallback onTap;
  final RealEstateTheme theme;

  const CountryField({
    super.key,
    required this.country,
    required this.label,
    required this.onTap,
    required this.theme,
    this.mode = CountryPickerMode.country,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final isCurrency = mode == CountryPickerMode.currency;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.textLabel,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCurrency
                        ? '${country.currencySymbol} · ${country.currencyName}'
                        : country.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
