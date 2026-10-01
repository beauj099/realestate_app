import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/count_stepper.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../data/models/unit_details.dart';

/// A flatlet's own layout: bachelor or how many bedrooms, then − n + for
/// bathrooms, kitchens, lounges and other rooms, and what makes it a unit of
/// its own (entrance, meter, parking, a tenant and the rent).
class FlatletLayout extends StatelessWidget {
  final UnitDetails unit;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final String currency;
  final ValueChanged<UnitDetails> onChanged;

  const FlatletLayout({
    super.key,
    required this.unit,
    required this.theme,
    required this.textTheme,
    required this.currency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final u = unit;
    Widget divider() =>
        Divider(height: 1, thickness: 1, color: theme.borderLight);
    Widget counter(
      String label,
      int value,
      ValueChanged<int> set, {
      int min = 0,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: theme.textPrimary),
            ),
          ),
          CountStepper(
            value: value,
            min: min,
            theme: theme,
            textTheme: textTheme,
            semanticsLabel: label.toLowerCase(),
            onChanged: set,
          ),
        ],
      ),
    );
    Widget toggle(String label, bool value, ValueChanged<bool> set) =>
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          dense: true,
          title: Text(
            label,
            style: textTheme.bodyLarge?.copyWith(color: theme.textPrimary),
          ),
          value: value,
          onChanged: set,
        );

    // Bachelor, 1, 2, 3+ bedrooms as chips; more than 3 with the counter.
    bool chosen(int b) => b == 3 ? u.bedrooms >= 3 : u.bedrooms == b;
    final sizes = [0, 1, 2, 3];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in sizes)
                  ChoiceChip(
                    label: Text(
                      b == 0
                          ? 'Bachelor'
                          : b == 3
                          ? '3+ bed'
                          : '$b bed',
                    ),
                    selected: chosen(b),
                    showCheckmark: false,
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: chosen(b) ? theme.onPrimary : theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        chosen(b) ? null : onChanged(u.copyWith(bedrooms: b)),
                  ),
              ],
            ),
          ),
          if (u.bedrooms >= 3)
            counter(
              'Bedrooms',
              u.bedrooms,
              (v) => onChanged(u.copyWith(bedrooms: v)),
              min: 3,
            ),
          divider(),
          counter(
            'Bathrooms',
            u.bathrooms,
            (v) => onChanged(u.copyWith(bathrooms: v)),
          ),
          counter(
            'Kitchens',
            u.kitchens,
            (v) => onChanged(u.copyWith(kitchens: v)),
          ),
          if (u.kitchens > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Full kitchen')),
                  ButtonSegment(value: true, label: Text('Kitchenette')),
                ],
                selected: {u.kitchenette},
                onSelectionChanged: (s) =>
                    onChanged(u.copyWith(kitchenette: s.first)),
              ),
            ),
          counter(
            'Lounges',
            u.lounges,
            (v) => onChanged(u.copyWith(lounges: v)),
          ),
          counter(
            'Other rooms',
            u.otherRooms,
            (v) => onChanged(u.copyWith(otherRooms: v)),
          ),
          divider(),
          toggle(
            'Own entrance',
            u.ownEntrance,
            (v) => onChanged(u.copyWith(ownEntrance: v)),
          ),
          toggle(
            'Own electricity meter',
            u.ownMeter,
            (v) => onChanged(u.copyWith(ownMeter: v)),
          ),
          toggle(
            'Own parking',
            u.parking,
            (v) => onChanged(u.copyWith(parking: v)),
          ),
          toggle('Let out', u.letOut, (v) => onChanged(u.copyWith(letOut: v))),
          if (u.letOut)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: CustomTextInput(
                theme: theme,
                label: 'Rent a month',
                prefixIcon: CurrencyPrefix(symbol: currency, theme: theme),
                initialValue: u.monthlyRent,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) => onChanged(u.copyWith(monthlyRent: v)),
              ),
            ),
        ],
      ),
    );
  }
}
