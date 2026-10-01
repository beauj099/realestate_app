import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "March 2014".
String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

/// A month and year: a year picker then a month, since owners rarely
/// remember the day.
class MonthYearField extends StatelessWidget {
  final String label;
  final String helpText;
  final DateTime? value;
  final RealEstateTheme theme;
  final ValueChanged<DateTime?> onChanged;

  const MonthYearField({
    super.key,
    required this.label,
    required this.helpText,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 5, now.month),
      firstDate: DateTime(1950),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: helpText,
    );
    if (picked != null) onChanged(DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    final v = value;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.cardBackgroundColor,
          border: border(theme.borderLight),
          enabledBorder: border(theme.borderLight),
          labelStyle: textTheme.bodyLarge?.copyWith(color: theme.textSecondary),
          suffixIcon: v == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          v == null ? 'Month and year' : monthYear(v),
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: v == null ? FontWeight.normal : FontWeight.w600,
            color: v == null ? theme.textSecondary : theme.textPrimary,
          ),
        ),
      ),
    );
  }
}
