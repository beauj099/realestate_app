import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/condition_selector.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/feature_list_widget.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../data/models/enums/condition_rating.dart';
import '../../data/models/enums/standard_amenity.dart';
import '../../data/models/room.dart';
import '../../providers/property_provider.dart';
import '../widgets/room_photo_gallery.dart';
import '../widgets/room_score_slider.dart';

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
          onBack: () {
            Navigator.maybePop(context);
          },
          theme: theme,
          actions: [
            IconButton(
              tooltip: 'Remove room',
              icon: Icon(Icons.delete_outline, color: theme.error),
              onPressed: () =>
                  _confirmRemoveRoom(context, viewModel, room, theme, textTheme),
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROOM IDENTITY',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textLabel,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          room.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: theme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => _showRenameDialog(
                            context,
                            viewModel,
                            room.id,
                            room.name,
                            theme,
                            textTheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  RoomPhotoGallery(
                    room: room,
                    baseUrl: ref.watch(apiClientProvider).baseUrl,
                    theme: theme,
                    textTheme: textTheme,
                    onAdd: (shots) => viewModel.addRoomPhotos(room.id, shots),
                    onRemove: (path) =>
                        viewModel.removeRoomPhoto(room.id, path),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Room Condition Rating',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rate the current state of the space.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConditionSelector(
                    selected: ConditionRating.fromStored(room.conditionRating),
                    theme: theme,
                    textTheme: textTheme,
                    onChanged: (rating) => viewModel.updateRoomDetails(
                      roomId: room.id,
                      conditionRating: rating.level,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: theme.borderLight),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Features & Amenities',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select all that apply to this space.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  () {
                    final allStandardAmenities = StandardAmenity.values
                        .map((a) => a.displayString)
                        .toSet();
                    // Only amenities relevant to this room type are offered.
                    // Already-selected standard features are kept visible too,
                    // so legacy rooms never lose a checked item after the fix.
                    final relevant = StandardAmenity.relevantForRoomTypeId(
                      room.roomTypeId,
                    ).map((a) => a.displayString).toSet();
                    final selectedStandard = room.features
                        .map((f) => f.description)
                        .where(allStandardAmenities.contains)
                        .toSet();
                    final visible = {...relevant, ...selectedStandard};
                    final visibleCategories = AmenityCategory.values
                        .where(
                          (c) => StandardAmenity.values.any(
                            (a) =>
                                a.category == c &&
                                visible.contains(a.displayString),
                          ),
                        )
                        .toList();
                    return Column(
                      children: [
                        ...visibleCategories.map((category) {
                          final amenities = StandardAmenity.values
                              .where(
                                (a) =>
                                    a.category == category &&
                                    visible.contains(a.displayString),
                              )
                              .map((a) => a.displayString)
                              .toList();
                          final selectedForCategory = room.features
                              .where((f) => amenities.contains(f.description))
                              .map((f) => f.description)
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.displayString,
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FeatureListWidget(
                                  selectedFeatures: selectedForCategory,
                                  availableDefaults: amenities,
                                  onAdd: (f) =>
                                      viewModel.addFeatureToRoom(room.id, f),
                                  onRemove: (f) => viewModel
                                      .removeFeatureFromRoom(room.id, f),
                                  categoryLabel: category.displayString,
                                  theme: theme,
                                  textTheme: textTheme,
                                ),
                              ],
                            ),
                          );
                        }),
                        () {
                          final customFeatures = room.features
                              .where(
                                (f) => !allStandardAmenities.contains(
                                  f.description,
                                ),
                              )
                              .toList();
                          if (customFeatures.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Custom',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...customFeatures.map(
                                  (f) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.cardBackgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.build_outlined,
                                          size: 18,
                                          color: theme.textSecondary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            f.description,
                                            style: textTheme.bodyLarge
                                                ?.copyWith(
                                                  color: theme.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: theme.textSecondary,
                                          ),
                                          onPressed: () =>
                                              viewModel.removeFeatureFromRoom(
                                                room.id,
                                                f.description,
                                              ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                      ],
                    );
                  }(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddFeatureDialog(
                        context,
                        viewModel,
                        room.id,
                        theme,
                        textTheme,
                      ),
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text('ADD CUSTOM FEATURE'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.cardBackgroundColor,
                        foregroundColor: theme.primaryColor,
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: theme.borderLight),
                  const SizedBox(height: 20),
                  CustomTextInput(
                    theme: theme,
                    label: 'Room notes',
                    placeholder:
                        'Add specific details about the condition or layout of this room...',
                    initialValue: room.notes,
                    maxLines: 4,
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
        // Pinned so the agent can commit the room without scrolling back down
        // past the whole amenity list.
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

  void _showAddFeatureDialog(
    BuildContext context,
    PropertyViewModel viewModel,
    String roomId,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    String feature = '';

    showRealEstateDialog(
      context: context,
      title: 'Add Amenity / Feature',
      theme: theme,
      content: CustomTextInput(
        theme: theme,
        label: 'Feature Name',
        placeholder: 'e.g. USB Outlets, Underfloor Heating',
        onChanged: (val) => feature = val,
      ),
      actions: [
        dialogCancelButton(context: context, theme: theme),
        dialogActionButton(
          theme: theme,
          text: 'Add',
          onPressed: () {
            if (feature.trim().isNotEmpty) {
              viewModel.addFeatureToRoom(roomId, feature.trim());
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
