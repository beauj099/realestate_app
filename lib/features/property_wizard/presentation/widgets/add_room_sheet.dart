import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/enums/room_category.dart';
import '../../providers/property_provider.dart';

class AddRoomSheet {
  static void show(
    BuildContext context,
    PropertyViewModel viewModel,
    RoomCategory category,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    final predefined = category.predefinedRoomTypes;

    showRealEstateBottomSheet(
      context: context,
      theme: theme,
      builder: (context) {
        String customName = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add ${category.displayString} Room',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a room type:',
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (predefined.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: predefined.map((type) {
                        return InkWell(
                          onTap: () {
                            viewModel.addCustomRoom(type, category.index + 1);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.borderLight),
                              borderRadius: BorderRadius.circular(16),
                              color: theme.cardBackgroundColor,
                            ),
                            child: Text(
                              type,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.borderLight)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: textTheme.labelLarge?.copyWith(
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: theme.borderLight)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Custom Room Name',
                    placeholder: 'e.g. Yoga Studio, Wine Cellar',
                    onChanged: (val) => customName = val,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: theme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (customName.trim().isNotEmpty) {
                            viewModel.addCustomRoom(
                              customName.trim(),
                              category.index + 1,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Add Custom',
                          style: TextStyle(color: theme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
