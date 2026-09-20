import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/searchable_picker.dart';
import '../../data/models/listing_parking.dart';
import '../../providers/property_provider.dart';

/// Parking-type picker.
///
/// Uses the same type-to-filter sheet as rooms, so the two "add" flows behave
/// identically and neither can be clipped by the keyboard or the safe area.
class AddParkingSheet {
  static Future<void> show(
    BuildContext context,
    PropertyViewModel viewModel,
    RealEstateTheme theme,
    TextTheme textTheme, {
    required Map<int, String> parkingTypes,
    required List<ListingParking> currentParking,
  }) async {
    final counts = <int, int>{
      for (final p in currentParking) p.parkingTypeId: p.quantity,
    };

    final result = await showSearchablePicker<int>(
      context: context,
      theme: theme,
      title: 'Add Parking',
      searchHint: 'Search parking types…',
      options: parkingTypes.entries.map((entry) {
        final count = counts[entry.key] ?? 0;
        return PickerOption<int>(
          value: entry.key,
          // Showing the running count keeps the sheet honest when an agent
          // adds a second or third bay of the same type.
          label: count > 0 ? '${entry.value}  ($count)' : entry.value,
          icon: _iconFor(entry.value),
        );
      }).toList(),
    );

    final typeId = result?.option?.value;
    if (typeId != null) viewModel.addParking(typeId);
  }

  static IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('carport')) return Icons.car_rental_outlined;
    if (l.contains('garage')) return Icons.garage_outlined;
    if (l.contains('undercover')) return Icons.umbrella_outlined;
    return Icons.local_parking_outlined;
  }
}
