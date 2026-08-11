import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/wizard_scaffold.dart';
import '../../data/models/enums/room_category.dart';
import '../../data/models/room.dart';
import '../../providers/property_provider.dart';
import '../widgets/room_section.dart';
import '../widgets/wizard_actions.dart';

class PropertyFeaturesStep extends ConsumerWidget {
  const PropertyFeaturesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final categories = RoomCategory.values;

    Map<RoomCategory, List<Room>> groupedRooms = {
      for (var cat in categories) cat: [],
    };
    for (var room in state.rooms) {
      final cat = RoomCategory.values.firstWhere(
        (c) => c.index + 1 == room.roomTypeId,
        orElse: () => RoomCategory.additional,
      );
      if (groupedRooms.containsKey(cat)) {
        groupedRooms[cat]!.add(room);
      }
    }

    return WizardScaffold(
      title: 'Property Features',
      description: 'Detail and configure every room in the residence.',
      onBack: () => goBackWizard(context, ref),
      onNext: () => advanceWizard(context, ref),
      children: [
        Text(
          'ROOMS',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textLabel,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        for (var category in categories) ...[
          RoomSection(
            theme: theme,
            textTheme: textTheme,
            category: category,
            rooms: groupedRooms[category]!,
            viewModel: viewModel,
            onRoomTap: (roomId) => context.push('/wizard/room-details/$roomId'),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
        Container(height: 1, color: theme.borderLight),
        const SizedBox(height: 20),
        Text(
          'PARKING',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textLabel,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          children: [
            {'id': 1, 'label': 'Single Garage'},
            {'id': 2, 'label': 'Double Garage'},
            {'id': 3, 'label': 'Triple Garage'},
            {'id': 4, 'label': 'Carport'},
            {'id': 5, 'label': 'Off-Street Parking'},
            {'id': 6, 'label': 'Undercover Parking'},
          ].map((p) {
            final pid = p['id'] as int;
            final label = p['label'] as String;
            final parkingItem = state.parking.where((p) => p.parkingTypeId == pid).firstOrNull;
            final isSelected = parkingItem != null;
            return CustomChip(
              theme: theme,
              label: isSelected ? '$label x${parkingItem.quantity}' : label,
              isSelected: isSelected,
              onTap: () {
                if (isSelected) {
                  viewModel.removeParking(pid);
                } else {
                  viewModel.addParking(pid);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
