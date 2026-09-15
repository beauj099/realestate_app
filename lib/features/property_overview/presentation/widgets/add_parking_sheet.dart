import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/listing_parking.dart';
import '../../providers/property_provider.dart';

class AddParkingSheet {
  static void show(
    BuildContext context,
    PropertyViewModel viewModel,
    RealEstateTheme theme,
    TextTheme textTheme, {
    required Map<int, String> parkingTypes,
    required List<ListingParking> currentParking,
  }) {
    final counts = <int, int>{
      for (final p in currentParking) p.parkingTypeId: p.quantity,
    };

    showRealEstateBottomSheet(
      context: context,
      theme: theme,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Parking',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a parking type:',
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: parkingTypes.entries.map((entry) {
                    final label = entry.value;
                    final typeId = entry.key;
                    final count = counts[typeId] ?? 0;
                    return InkWell(
                      onTap: () {
                        viewModel.addParking(typeId);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: count > 0
                                ? theme.primaryColor
                                : theme.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: theme.cardBackgroundColor,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: theme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
