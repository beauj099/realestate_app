import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/searchable_picker.dart';
import '../../data/models/enums/room_category.dart';
import '../../providers/property_provider.dart';

/// Room-type picker.
///
/// Was a full-sheet wall of chips covering every room type at once. It is now a
/// type-to-filter list: "kit" reaches Kitchen in three keystrokes instead of a
/// scroll hunt through seven category blocks. Typing a name nothing matches
/// offers it as a custom room, which is how the old free-text box worked.
class AddRoomSheet {
  /// Shows the picker and returns the id of the room that was added, or `null`
  /// when the agent backed out. Callers use the id to open the new room.
  static Future<String?> show(
    BuildContext context,
    PropertyViewModel viewModel,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) async {
    final result = await showSearchablePicker<String>(
      context: context,
      theme: theme,
      title: 'Add Room',
      searchHint: 'Search room types…',
      customLabel: 'Add Custom',
      customHint: 'Add',
      options: [
        for (final category in RoomCategory.values)
          for (final type in category.predefinedRoomTypes)
            PickerOption<String>(
              value: type,
              label: type,
              group: category.displayString,
              icon: category.icon,
            ),
      ],
    );

    if (result == null) return null;

    if (result.isCustom) {
      final name = result.customLabel!;
      return viewModel.addCustomRoom(
        name,
        RoomCategoryExtension.roomTypeIdForType(name),
      );
    }

    final type = result.option!.value;
    return viewModel.addCustomRoom(
      type,
      RoomCategoryExtension.roomTypeIdForType(type),
    );
  }
}
