import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/multi_select_sheet.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../data/models/enums/condition_rating.dart';
import '../../data/models/enums/standard_amenity.dart';
import '../../data/models/room.dart';
import '../../providers/property_provider.dart';
import '../widgets/room_photo_gallery.dart';
import '../widgets/room_score_slider.dart';
import '../widgets/section_list.dart';

/// One room: photos, condition, features, notes and score.
///
/// Laid out like Property Features — section headers over compact cards —
/// with the room's name in the app bar instead of a card of its own. Edits
/// go into the shared property state and are saved with Property Features.
class RoomDetailsScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final room = state.rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => state.rooms.first,
    );
    final groups = _FeatureGroup.forRoom(room);
    final featureCount = room.features.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        viewModel.selectRoomForEditing(null);
        context.pop();
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: room.name,
          onBack: () => Navigator.maybePop(context),
          theme: theme,
          actions: [
            IconButton(
              tooltip: 'Rename room',
              icon: Icon(Icons.edit_outlined, color: theme.textSecondary),
              onPressed: () => _showRenameDialog(
                context,
                viewModel,
                room.id,
                room.name,
                theme,
                textTheme,
              ),
            ),
            IconButton(
              tooltip: 'Remove room',
              icon: Icon(Icons.delete_outline, color: theme.error),
              onPressed: () => _confirmRemoveRoom(
                context,
                viewModel,
                room,
                theme,
                textTheme,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoomPhotoGallery(
                    room: room,
                    baseUrl: ref.watch(apiClientProvider).baseUrl,
                    theme: theme,
                    textTheme: textTheme,
                    onAdd: (shots) => viewModel.addRoomPhotos(room.id, shots),
                    onRemove: (path) =>
                        viewModel.removeRoomPhoto(room.id, path),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Condition',
                    theme: theme,
                    textTheme: textTheme,
                  ),
                  _ConditionChips(
                    selected: ConditionRating.fromStored(room.conditionRating),
                    theme: theme,
                    textTheme: textTheme,
                    onChanged: (rating) => viewModel.updateRoomDetails(
                      roomId: room.id,
                      conditionRating: rating.level,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Features',
                    detail: featureCount == 0 ? null : '$featureCount ticked',
                    theme: theme,
                    textTheme: textTheme,
                  ),
                  RowsCard(
                    theme: theme,
                    children: [
                      for (final group in groups)
                        _FeatureGroupRow(
                          group: group,
                          selected: group.selectedFrom(room),
                          theme: theme,
                          textTheme: textTheme,
                          onTap: () async {
                            final picked = await showMultiSelectSheet<String>(
                              context: context,
                              theme: theme,
                              title: group.label,
                              options: group.options,
                              labelOf: (f) => f,
                              initiallySelected: group.selectedFrom(room),
                              confirmLabel: 'Done',
                              allowEmpty: true,
                              createCustom: group.allowsCustom
                                  ? (text) => text
                                  : null,
                            );
                            if (picked != null) {
                              viewModel.setRoomFeaturesInGroup(
                                room.id,
                                group.options,
                                picked,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Notes',
                    theme: theme,
                    textTheme: textTheme,
                  ),
                  CustomTextInput(
                    theme: theme,
                    label: 'Room notes',
                    placeholder:
                        'Anything specific about the condition or layout…',
                    initialValue: room.notes,
                    maxLines: 3,
                    onChanged: (val) => viewModel.updateRoomDetails(
                      roomId: room.id,
                      notes: val,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Last on purpose: the score sums up everything above it.
                  RoomScoreSlider(
                    score: room.score,
                    theme: theme,
                    textTheme: textTheme,
                    onChanged: (score) =>
                        viewModel.setRoomScore(room.id, score),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Pinned so the agent can finish the room without scrolling back.
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            border: Border(top: BorderSide(color: theme.borderLight)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: CustomButton(
                  text: 'Done',
                  fullWidth: true,
                  theme: theme,
                  onTap: () {
                    viewModel.selectRoomForEditing(null);
                    context.pop();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Removes the room (on the next Property Features save) and returns to
  /// the room list.
  Future<void> _confirmRemoveRoom(
    BuildContext context,
    PropertyViewModel viewModel,
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
    if (confirmed != true || !context.mounted) return;
    viewModel.selectRoomForEditing(null);
    context.pop();
    viewModel.removeRoom(room.id);
  }

  void _showRenameDialog(
    BuildContext context,
    PropertyViewModel viewModel,
    String roomId,
    String currentName,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    String name = currentName;

    showRealEstateDialog(
      context: context,
      title: 'Rename Room',
      theme: theme,
      content: CustomTextInput(
        theme: theme,
        label: 'Room Name',
        textCapitalization: TextCapitalization.words,
        placeholder: 'e.g. Master Bedroom Suite',
        initialValue: currentName,
        onChanged: (val) => name = val,
      ),
      actions: [
        dialogCancelButton(context: context, theme: theme),
        dialogActionButton(
          theme: theme,
          text: 'Save',
          onPressed: () {
            if (name.trim().isNotEmpty) {
              viewModel.renameRoom(roomId, name.trim());
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}

/// The six condition bands as one wrap of compact chips.
class _ConditionChips extends StatelessWidget {
  final ConditionRating? selected;
  final ValueChanged<ConditionRating> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _ConditionChips({
    required this.selected,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final rating in ConditionRating.values)
          ChoiceChip(
            label: Text(rating.label),
            selected: rating == selected,
            onSelected: (_) => onChanged(rating),
            showCheckmark: false,
            selectedColor: theme.primaryColor,
            backgroundColor: theme.cardBackgroundColor,
            side: BorderSide(
              color: rating == selected
                  ? theme.primaryColor
                  : theme.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: textTheme.bodyMedium?.copyWith(
              color: rating == selected ? theme.onPrimary : theme.textPrimary,
              fontWeight: rating == selected
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// One group of room features, or "Other" for anything custom.
class _FeatureGroup {
  final String label;
  final IconData icon;
  final List<String> options;
  final bool allowsCustom;

  const _FeatureGroup({
    required this.label,
    required this.icon,
    required this.options,
    this.allowsCustom = false,
  });

  List<String> selectedFrom(Room room) => [
    for (final f in room.features)
      if (options.contains(f.description)) f.description,
  ];

  static IconData _iconFor(AmenityCategory category) {
    switch (category) {
      case AmenityCategory.kitchen:
        return Icons.kitchen_outlined;
      case AmenityCategory.bathroom:
        return Icons.bathtub_outlined;
      case AmenityCategory.storage:
        return Icons.checkroom_outlined;
      case AmenityCategory.layout:
        return Icons.door_sliding_outlined;
      case AmenityCategory.living:
        return Icons.fireplace_outlined;
      case AmenityCategory.floors:
        return Icons.layers_outlined;
      case AmenityCategory.climateFinishes:
        return Icons.ac_unit_outlined;
      case AmenityCategory.legacyWholeHouse:
        return Icons.home_outlined;
    }
  }

  /// The groups this kind of room offers, in catalogue order, then "Other".
  /// A legacy whole-house feature already on the room still gets its group,
  /// so it can be seen and removed.
  static List<_FeatureGroup> forRoom(Room room) {
    final relevant = StandardAmenity.relevantForRoomTypeId(room.roomTypeId);
    final ticked = room.features.map((f) => f.description).toSet();
    final known = StandardAmenity.values.map((a) => a.displayString).toSet();

    return [
      for (final category in AmenityCategory.values)
        if (StandardAmenity.values
                .where(
                  (a) =>
                      a.category == category &&
                      (relevant.contains(a) ||
                          ticked.contains(a.displayString)),
                )
                .map((a) => a.displayString)
                .toList()
            case final options when options.isNotEmpty)
          _FeatureGroup(
            label: category.displayString,
            icon: _iconFor(category),
            options: options,
          ),
      _FeatureGroup(
        label: 'Other',
        icon: Icons.more_horiz,
        options: [
          for (final f in room.features)
            if (!known.contains(f.description)) f.description,
        ],
        allowsCustom: true,
      ),
    ];
  }
}

class _FeatureGroupRow extends StatelessWidget {
  final _FeatureGroup group;
  final List<String> selected;
  final VoidCallback onTap;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _FeatureGroupRow({
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
