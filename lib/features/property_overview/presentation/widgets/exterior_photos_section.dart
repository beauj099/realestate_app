import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/listing_photo.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../providers/property_provider.dart';

/// Exterior shots of the property, with one nominated as the hero image.
///
/// The hero is what identifies the listing at a glance on the home screen —
/// a photo of the house says more than a reference number ever will. The
/// first photo in the list is the hero; tapping any other offers to promote it.
class ExteriorPhotosSection extends StatelessWidget {
  final List<String> photos;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final PropertyViewModel viewModel;

  const ExteriorPhotosSection({
    super.key,
    required this.photos,
    required this.theme,
    required this.textTheme,
    required this.viewModel,
  });

  Future<void> _addPhoto(BuildContext context) async {
    final source = await showRealEstateBottomSheet<ImageSource>(
      context: context,
      theme: theme,
      builder: (sheetContext) => SafeArea(
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
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null) viewModel.addExteriorPhoto(picked.path);
  }

  Future<void> _photoActions(BuildContext context, String path) async {
    final isMain = photos.isNotEmpty && photos.first == path;
    final action = await showRealEstateBottomSheet<String>(
      context: context,
      theme: theme,
      builder: (sheetContext) => SafeArea(
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
              if (!isMain)
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Set as main photo'),
                  onTap: () => Navigator.pop(sheetContext, 'main'),
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.error),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: theme.error),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'main') viewModel.setMainExteriorPhoto(path);
    if (action == 'remove') viewModel.removeExteriorPhoto(path);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PHOTOS',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.textLabel,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (photos.isNotEmpty)
              TextButton.icon(
                onPressed: () => _addPhoto(context),
                icon: Icon(Icons.add, size: 16, color: theme.primaryColor),
                label: Text(
                  'Add',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          _EmptyPhotoPrompt(
            theme: theme,
            textTheme: textTheme,
            onTap: () => _addPhoto(context),
          )
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Detach from the PrimaryScrollController: this strip lives
              // inside the overview's vertical scroll view, and sharing the
              // primary controller makes hover hit-tests during the pop
              // transition walk a detaching viewport (viewport.dart:1034).
              primary: false,
              physics: const ClampingScrollPhysics(),
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final path = photos[index];
                return _PhotoTile(
                  path: path,
                  isMain: index == 0,
                  theme: theme,
                  textTheme: textTheme,
                  onTap: () => _photoActions(context, path),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyPhotoPrompt extends StatelessWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _EmptyPhotoPrompt({
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderLight),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 30,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              'Add exterior photos',
              style: textTheme.titleMedium?.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Front view first — it becomes the listing photo',
              style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final bool isMain;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.path,
    required this.isMain,
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMain ? theme.primaryColor : theme.borderLight,
            width: isMain ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            listingPhoto(
              path,
              theme: theme,
              textTheme: textTheme,
              fit: BoxFit.cover,
            ),
            if (isMain)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'MAIN',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
