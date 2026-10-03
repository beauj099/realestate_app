import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/multi_select_sheet.dart';
import 'section_list.dart';

/// A heading over a group of fields.
class FieldHeading extends StatelessWidget {
  final String text;
  final String? hint;
  final RealEstateTheme theme;

  const FieldHeading(this.text, {super.key, this.hint, required this.theme});

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
              fontSize: 15,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// One choice from a few, as chips; tapping the chosen one again clears it.
class SingleChoiceChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final RealEstateTheme theme;

  const SingleChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final o in options)
          CustomChip(
            theme: theme,
            label: o,
            isSelected: o == selected,
            onTap: () => onChanged(o == selected ? '' : o),
          ),
      ],
    );
  }
}

/// Several from a list, as chips (for short lists).
class MultiChoiceChips extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final RealEstateTheme theme;

  const MultiChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final o in options)
          CustomChip(
            theme: theme,
            label: o,
            isSelected: selected.contains(o),
            onTap: () => onChanged(
              selected.contains(o)
                  ? [
                      for (final s in selected)
                        if (s != o) s,
                    ]
                  : [...selected, o],
            ),
          ),
      ],
    );
  }
}

/// A row that opens a pick sheet: the title, what is chosen, and an icon.
/// [multi] picks several (tick and confirm); else one, which closes the
/// sheet as it is tapped.
class PickRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool multi;
  final RealEstateTheme theme;

  const PickRow({
    super.key,
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.theme,
    this.multi = true,
  });

  Future<void> _open(BuildContext context) async {
    if (multi) {
      final picked = await showMultiSelectSheet<String>(
        context: context,
        theme: theme,
        title: title,
        options: options,
        labelOf: (o) => o,
        initiallySelected: selected,
        confirmLabel: 'Done',
        allowEmpty: true,
      );
      if (picked != null) onChanged(picked);
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.cardBackgroundColor,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: selected.contains(o)
                    ? Icon(Icons.check, color: theme.primaryColor)
                    : null,
                onTap: () => Navigator.pop(sheet, o),
              ),
            if (selected.isNotEmpty)
              ListTile(
                title: Text(
                  'Clear',
                  style: TextStyle(color: theme.textSecondary),
                ),
                onTap: () => Navigator.pop(sheet, ''),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked.isEmpty ? const [] : [picked]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            RowIcon(icon: icon, theme: theme, muted: selected.isEmpty),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.isEmpty ? 'Not set' : selected.join(', '),
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                      fontSize: 12.5,
                    ),
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

/// A date, picked from a calendar; a cross clears it.
class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final RealEstateTheme theme;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.firstDate,
    this.lastDate,
  });

  static final _format = DateFormat('d MMMM yyyy');

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 30),
      lastDate: lastDate ?? DateTime(now.year + 5),
      helpText: label,
    );
    if (picked != null) onChanged(picked);
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
              ? const Icon(Icons.event_outlined)
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          v == null ? 'Choose a date' : _format.format(v),
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: v == null ? FontWeight.normal : FontWeight.w600,
            color: v == null ? theme.textSecondary : theme.textPrimary,
          ),
        ),
      ),
    );
  }
}
