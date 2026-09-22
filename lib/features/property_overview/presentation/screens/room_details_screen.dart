import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/photo_urls.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/condition_selector.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/feature_list_widget.dart';
import '../../../../core/widgets/platform_image.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../data/models/enums/condition_rating.dart';
import '../../data/models/enums/standard_amenity.dart';
import '../../data/models/room.dart';
import '../../providers/property_provider.dart';

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
                  _buildRoomGraphic(
                    context,
                    theme,
                    textTheme,
                    room,
                    viewModel,
                    ref.watch(apiClientProvider).baseUrl,
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
                    return Column(
                      children: [
                        ...AmenityCategory.values.map((category) {
                          final amenities = StandardAmenity.values
                              .where((a) => a.category == category)
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

  Widget _buildRoomGraphic(
    BuildContext context,
    RealEstateTheme theme,
    TextTheme textTheme,
    Room room,
    PropertyViewModel viewModel,
    String baseUrl,
  ) {
    final hasImage = room.photoUrl != null;

    return GestureDetector(
      onTap: () => _showImagePickerOptions(
        context,
        viewModel,
        room.id,
        theme,
        textTheme,
      ),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: !hasImage ? theme.imagePlaceholder : null,
          borderRadius: BorderRadius.circular(16.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage && isRemotePhoto(room.photoUrl!))
                Image.network(
                  resolvePhotoUrl(room.photoUrl!, baseUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.imagePlaceholder,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: theme.mutedIcon,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to retry',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.mutedIcon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (hasImage && !isRemotePhoto(room.photoUrl!))
                localFileImage(
                  room.photoUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.imagePlaceholder,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: theme.mutedIcon,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to retry',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.mutedIcon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!hasImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        theme.shadow.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Tap to add room photo',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.shadow.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImagePickerOptions(
    BuildContext context,
    PropertyViewModel viewModel,
    String roomId,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) async {
    final result = await showRealEstateBottomSheet<String>(
      context: context,
      theme: theme,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final ImageSource source = result == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked != null) {
      // Cache bytes at pick time: on the web the path is only a blob URL
      // and the upload must use `MultipartFile.fromBytes`.
      final bytes = await picked.readAsBytes();
      viewModel.updateRoomDetails(
        roomId: roomId,
        photoUrl: picked.path,
        photoBytes: bytes,
        photoFilename: picked.name,
      );
    }
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
