import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/listing_photo.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../data/models/room.dart';

typedef RoomShot = ({String path, Uint8List? bytes, String? filename});

/// A room's photos as a strip of thumbnails, first one marked as the cover,
/// with an add tile showing how many of the [Room.maxPhotos] are used.
///
/// Photos are only held locally until the Property Features section is
/// saved, like every other room detail.
class RoomPhotoGallery extends StatelessWidget {
  final Room room;
  final String baseUrl;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<List<RoomShot>> onAdd;
  final ValueChanged<String> onRemove;

  const RoomPhotoGallery({
    super.key,
    required this.room,
    required this.baseUrl,
    required this.theme,
    required this.textTheme,
    required this.onAdd,
    required this.onRemove,
  });

  static const double _tile = 96;

  int get _remaining => Room.maxPhotos - room.photos.length;

  Future<void> _add(BuildContext context) async {
    if (_remaining <= 0) return;
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
                title: Text('Choose from gallery (up to $_remaining)'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      picked = shot == null ? const [] : [shot];
    } else {
      picked = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
        limit: _remaining > 1 ? _remaining : null,
      );
    }
    if (picked.isEmpty) return;

    final shots = <RoomShot>[
      // Bytes are cached at pick time for the web, where the path is only a
      // blob URL.
      for (final x in picked.take(_remaining))
        (path: x.path, bytes: await x.readAsBytes(), filename: x.name),
    ];
    if (picked.length > _remaining && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A room holds ${Room.maxPhotos} photos; '
            'only the first $_remaining were added.',
          ),
        ),
      );
    }
    onAdd(shots);
  }

  Future<void> _photoActions(BuildContext context, RoomPhoto photo) async {
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
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.error),
                title: Text('Remove', style: TextStyle(color: theme.error)),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'remove') onRemove(photo.path);
  }

  @override
  Widget build(BuildContext context) {
    final photos = room.photos;

    if (photos.isEmpty) {
      return InkWell(
        onTap: () => _add(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 32,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Add room photos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                'Up to ${Room.maxPhotos} — the first is the cover',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${photos.length} / ${Room.maxPhotos}',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _tile,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + (_remaining > 0 ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == photos.length) return _addTile(context);
              final photo = photos[i];
              return GestureDetector(
                onTap: () => _photoActions(context, photo),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: _tile,
                    height: _tile,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        listingPhoto(
                          photo.path,
                          theme: theme,
                          textTheme: textTheme,
                          cacheWidth: 300,
                          baseUrl: baseUrl,
                        ),
                        if (i == 0)
                          Positioned(
                            left: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'COVER',
                                style: textTheme.labelSmall?.copyWith(
                                  color: theme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        if (!photo.isUploaded)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 16,
                              color: theme.onPrimary,
                              semanticLabel: 'Uploads when you save',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _addTile(BuildContext context) {
    return InkWell(
      onTap: () => _add(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: _tile,
        height: _tile,
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: theme.primaryColor),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: textTheme.labelMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
