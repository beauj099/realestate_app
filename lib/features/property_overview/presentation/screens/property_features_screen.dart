import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/multi_select_sheet.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/enums/condition_rating.dart';
import '../../data/models/enums/outdoor_extra.dart';
import '../../data/models/enums/room_category.dart';
import '../../data/models/listing_parking.dart';
import '../../data/models/property_state.dart';
import '../../data/models/room.dart';
import '../../data/models/room_score.dart';
import '../../providers/property_provider.dart';
import '../widgets/add_room_sheet.dart';
import '../widgets/section_list.dart';
import '../widgets/wizard_section_scaffold.dart';

/// Rooms, parking and outdoor features.
///
/// Laid out like a settings list: each section has one header with a small
/// "Add" action, and a single card of compact rows beneath it. Rooms open for
/// detail and swipe away to delete; parking types carry their own − n +
/// counter; each outdoor category is one row summarising what is ticked.
class PropertyFeaturesScreen extends ConsumerWidget {
  const PropertyFeaturesScreen({super.key});

  /// Adds a room, then opens it straight away — picking the type is only the
  /// start of describing it.
  Future<void> _addRoomAndOpen(
    BuildContext context,
    PropertyViewModel viewModel,
    RealEstateTheme theme,
    TextTheme textTheme,
    int? listingId,
  ) async {
    final roomId = await AddRoomSheet.show(
      context,
      viewModel,
      theme,
      textTheme,
    );
    if (roomId == null || listingId == null || !context.mounted) return;
    viewModel.selectRoomForEditing(roomId);
    context.push(AppRoutes.roomDetails(listingId, roomId));
  }

  Future<bool> _confirmDeleteRoom(
    BuildContext context,
    Room room,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) async {
    final confirmed = await showRealEstateDialog<bool>(
      context: context,
      title: 'Remove Room',
      theme: theme,
      content: Text(
        'Remove "${room.name}"? This takes effect when you save.',
        style: textTheme.bodyLarge,
      ),
      actions: [
        dialogCancelButton(context: context, theme: theme),
        dialogActionButton(
          theme: theme,
          text: 'Remove',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    return confirmed ?? false;
  }

  Future<void> _addParking(
    BuildContext context,
    PropertyViewModel viewModel,
    RealEstateTheme theme,
    Map<int, String> parkingTypes,
    List<ListingParking> current,
  ) async {
    final existing = current.map((p) => p.parkingTypeId).toSet();
    final picked = await showMultiSelectSheet<int>(
      context: context,
      theme: theme,
      title: 'Add Parking',
      subtitle: 'Tick every kind of parking, then set how many of each.',
      confirmLabel: 'Continue',
      options: parkingTypes.keys.where((id) => !existing.contains(id)).toList(),
      labelOf: (id) => parkingTypes[id] ?? 'Parking type $id',
      iconOf: (id) => parkingIcon(parkingTypes[id] ?? ''),
    );
    if (picked != null) viewModel.addParkingTypes(picked);
  }

  Future<void> _editOutdoorCategory(
    BuildContext context,
    PropertyViewModel viewModel,
    RealEstateTheme theme,
    _OutdoorGroup group,
    List<String> selected,
  ) async {
    final picked = await showMultiSelectSheet<String>(
      context: context,
      theme: theme,
      title: group.label,
      options: group.options,
      labelOf: (f) => f,
      initiallySelected: selected,
      confirmLabel: 'Done',
      allowEmpty: true,
      createCustom: group.allowsCustom ? (text) => text : null,
    );
    if (picked != null) {
      viewModel.setOutdoorFeaturesInCategory(group.options, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final listingId = state.listingId;
    final rooms = state.rooms;
    final parkingTypes = ref
        .watch(parkingTypesProvider)
        .maybeWhen(data: (types) => types, orElse: () => fallbackParkingTypes);
    final outdoorGroups = _OutdoorGroup.all(state.outdoorFeatures);

    return WizardSectionScaffold(
      title: 'Property Features',
      sectionName: 'property features',
      topPadding: 8,
      onSave: () async {
        await viewModel.savePropertyFeatures();
        final error = ref.read(propertyViewModelProvider).errorMessage;
        return error == null
            ? null
            : friendlySaveMessage(error, 'property features');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Rooms',
            detail: rooms.isEmpty
                ? null
                : '${state.ratedRoomCount} of ${rooms.length} rated',
            theme: theme,
            textTheme: textTheme,
            onAdd: () => _addRoomAndOpen(
              context,
              viewModel,
              theme,
              textTheme,
              listingId,
            ),
          ),
          RowsCard(
            theme: theme,
            emptyText: 'No rooms yet. Tap Add to list the first one.',
            children: [
              for (final room in rooms)
                Dismissible(
                  key: ValueKey(room.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) =>
                      _confirmDeleteRoom(context, room, theme, textTheme),
                  onDismissed: (_) => viewModel.removeRoom(room.id),
                  background: Container(
                    color: theme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete_outline, color: theme.onPrimary),
                  ),
                  child: _RoomRow(
                    room: room,
                    theme: theme,
                    textTheme: textTheme,
                    onTap: listingId == null
                        ? null
                        : () {
                            viewModel.selectRoomForEditing(room.id);
                            context.push(
                              AppRoutes.roomDetails(listingId, room.id),
                            );
                          },
                  ),
                ),
            ],
          ),
          if (rooms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                'Swipe a room left to remove it.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Parking',
            theme: theme,
            textTheme: textTheme,
            onAdd: parkingTypes.length == state.parking.length
                ? null
                : () => _addParking(
                    context,
                    viewModel,
                    theme,
                    parkingTypes,
                    state.parking,
                  ),
          ),
          RowsCard(
            theme: theme,
            emptyText: 'No parking. Tap Add to choose garages, carports…',
            children: [
              for (final p in state.parking)
                _ParkingRow(
                  label:
                      parkingTypes[p.parkingTypeId] ??
                      'Parking type ${p.parkingTypeId}',
                  quantity: p.quantity,
                  theme: theme,
                  textTheme: textTheme,
                  onChanged: (qty) =>
                      viewModel.setParkingQuantity(p.parkingTypeId, qty),
                ),
            ],
          ),
          if (state.parking.any((p) => p.quantity == 0))
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                'Types set to 0 are removed when you save.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Outdoor & Extras',
            theme: theme,
            textTheme: textTheme,
          ),
          RowsCard(
            theme: theme,
            children: [
              for (final group in outdoorGroups)
                _OutdoorRow(
                  group: group,
                  selected: group.selectedFrom(state.outdoorFeatures),
                  theme: theme,
                  textTheme: textTheme,
                  onTap: () => _editOutdoorCategory(
                    context,
                    viewModel,
                    theme,
                    group,
                    group.selectedFrom(state.outdoorFeatures),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon for a parking type, from its name.
IconData parkingIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('carport')) return Icons.car_rental_outlined;
  if (l.contains('garage')) return Icons.garage_outlined;
  if (l.contains('undercover')) return Icons.umbrella_outlined;
  return Icons.local_parking_outlined;
}

class _RoomRow extends StatelessWidget {
  final Room room;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  const _RoomRow({
    required this.room,
    required this.theme,
    required this.textTheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rated = PropertyState.isRoomRated(room);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            RowIcon(
              icon: RoomCategoryExtension.categoryForRoomTypeId(
                room.roomTypeId,
              ).icon,
              theme: theme,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _roomSummary(room),
                    style: textTheme.bodyMedium?.copyWith(
                      color: rated ? theme.textSecondary : theme.pendingColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              rated ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 22,
              color: rated ? theme.completeColor : theme.pendingColor,
              semanticLabel: rated ? 'Rated' : 'Not rated',
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingRow extends StatelessWidget {
  final String label;
  final int quantity;
  final ValueChanged<int> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _ParkingRow({
    required this.label,
    required this.quantity,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final removed = quantity == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          RowIcon(icon: parkingIcon(label), theme: theme, muted: removed),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: removed ? theme.textSecondary : theme.textPrimary,
                decoration: removed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          _Stepper(
            value: quantity,
            onChanged: onChanged,
            theme: theme,
            textTheme: textTheme,
            semanticsLabel: label,
          ),
        ],
      ),
    );
  }
}

/// − n + counter, like the guest/bed counters in booking apps.
class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final String semanticsLabel;

  static const int max = 20;

  const _Stepper({
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
    required this.semanticsLabel,
  });

  Widget _button(IconData icon, VoidCallback? onPressed, String tooltip) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton.outlined(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          foregroundColor: theme.primaryColor,
          disabledForegroundColor: theme.borderLight,
          side: BorderSide(
            color: onPressed == null
                ? theme.borderLight
                : theme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          Icons.remove,
          value > 0 ? () => onChanged(value - 1) : null,
          'Fewer $semanticsLabel',
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
        ),
        _button(
          Icons.add,
          value < max ? () => onChanged(value + 1) : null,
          'More $semanticsLabel',
        ),
      ],
    );
  }
}

/// One outdoor category — or "Other" for custom entries — as a single row.
class _OutdoorGroup {
  final String label;
  final IconData icon;
  final List<String> options;
  final bool allowsCustom;

  const _OutdoorGroup({
    required this.label,
    required this.icon,
    required this.options,
    this.allowsCustom = false,
  });

  List<String> selectedFrom(List<String> features) =>
      features.where(options.contains).toList();

  static IconData _iconFor(OutdoorExtraCategory category) {
    switch (category) {
      case OutdoorExtraCategory.outdoorLiving:
        return Icons.deck_outlined;
      case OutdoorExtraCategory.extraStructures:
        return Icons.cottage_outlined;
      case OutdoorExtraCategory.security:
        return Icons.security_outlined;
      case OutdoorExtraCategory.energyWater:
        return Icons.solar_power_outlined;
      case OutdoorExtraCategory.parking:
        return Icons.local_parking_outlined;
    }
  }

  /// The listed categories, then "Other" holding anything the agent typed.
  /// Parking has its own section with counts.
  static List<_OutdoorGroup> all(List<String> features) {
    final known = OutdoorExtra.values.map((e) => e.displayString).toSet();
    return [
      for (final category in OutdoorExtraCategory.values)
        if (category != OutdoorExtraCategory.parking)
          _OutdoorGroup(
            label: category.displayString,
            icon: _iconFor(category),
            options: category.displayStrings,
          ),
      _OutdoorGroup(
        label: 'Other',
        icon: Icons.more_horiz,
        options: features.where((f) => !known.contains(f)).toList(),
        allowsCustom: true,
      ),
    ];
  }
}

class _OutdoorRow extends StatelessWidget {
  final _OutdoorGroup group;
  final List<String> selected;
  final VoidCallback onTap;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _OutdoorRow({
    required this.group,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = selected.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            RowIcon(icon: group.icon, theme: theme, muted: !hasAny),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasAny
                        ? selected.join(', ')
                        : group.allowsCustom
                        ? 'Add anything not listed above'
                        : 'None',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary.withValues(
                        alpha: hasAny ? 1 : 0.7,
                      ),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasAny) ...[
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 26),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selected.length}',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Good · Score 7.5", "Score 6", "Good" or "Not rated yet".
String _roomSummary(Room room) {
  final condition = ConditionRating.fromStored(room.conditionRating)?.label;
  final score = room.score;
  final parts = [
    ?condition,
    if (score != null) 'Score ${RoomScore.format(score)}',
  ];
  return parts.isEmpty ? 'Not rated yet' : parts.join(' · ');
}
