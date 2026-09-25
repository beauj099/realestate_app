import 'package:flutter/material.dart';

import '../locale/countries.dart';
import '../theme/themes.dart';

/// A fixed label in front of a field, set apart by a divider, so the agent
/// only types the part that varies.
class _FieldPrefix extends StatelessWidget {
  final Widget child;
  final RealEstateTheme theme;

  const _FieldPrefix({required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(width: 12),
            VerticalDivider(width: 1, thickness: 1, color: theme.borderLight),
          ],
        ),
      ),
    );
  }
}

/// The flag and dialling code of the agent's country in front of a phone
/// field, e.g. "🇿🇦 +27". Changes with the country chosen in Settings.
class PhonePrefix extends StatelessWidget {
  final Country country;
  final RealEstateTheme theme;

  const PhonePrefix({super.key, required this.country, required this.theme});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return _FieldPrefix(
      theme: theme,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            country.dialPrefix,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The currency symbol in front of a money field, e.g. "R", so the agent
/// never types it. Follows the currency chosen in Settings.
class CurrencyPrefix extends StatelessWidget {
  final String symbol;
  final RealEstateTheme theme;

  const CurrencyPrefix({super.key, required this.symbol, required this.theme});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return _FieldPrefix(
      theme: theme,
      child: Text(
        symbol,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
      ),
    );
  }
}
