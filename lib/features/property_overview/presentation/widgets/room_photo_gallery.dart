import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../data/models/room.dart';
import 'photo_strip.dart';

typedef RoomShot = PickedShot;

/// A room's photos as a strip of thumbnails, the first marked as the cover,
/// with an add tile showing how many of the [Room.maxPhotos] are used. The
/// agent reorders by holding and dragging, or taps a photo to make it the
/// cover.
///
/// Photos and their order are held locally until the Property Features
/// section is saved, like every other room detail.
class RoomPhotoGallery extends StatelessWidget {
  final Room room;
  final String baseUrl;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<List<RoomShot>> onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onMakeCover;
  final ValueChanged<List<String>> onReorder;

  const RoomPhotoGallery({
    super.key,
    required this.room,
    required this.baseUrl,
    required this.theme,
    required this.textTheme,
    required this.onAdd,
    required this.onRemove,
    required this.onMakeCover,
    required this.onReorder,
  });

  static const double _tile = 104;

  int get _remaining => Room.maxPhotos - room.photos.length;

  Future<void> _add(BuildContext context) async {
    final shots = await pickPhotos(
      context: context,
      theme: theme,
      remaining: _remaining,
    );
    if (shots.isNotEmpty) onAdd(shots);
  }

  Future<void> _photoActions(BuildContext context, String path) async {
    final action = await showPhotoActions(
      context: context,
      theme: theme,
      isFirst: room.photos.isNotEmpty && room.photos.first.path == path,
      firstLabel: 'cover photo',
    );
    if (action == PhotoAction.makeFirst) onMakeCover(path);
    if (action == PhotoAction.remove) onRemove(path);
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
              style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ReorderablePhotoStrip(
          paths: [for (final p in photos) p.path],
          baseUrl: baseUrl,
          theme: theme,
          textTheme: textTheme,
          firstBadge: 'COVER',
          tileWidth: _tile,
          tileHeight: _tile,
          onReorder: onReorder,
          onTap: (path) => _photoActions(context, path),
          trailing: _remaining > 0
              ? AddPhotoTile(
                  theme: theme,
                  textTheme: textTheme,
                  width: _tile,
                  height: _tile,
                  onTap: () => _add(context),
                )
              : null,
        ),
        if (photos.length > 1)
          PhotoStripHint(
            text: 'Hold and drag to reorder. Tap a photo to make it the cover.',
            theme: theme,
            textTheme: textTheme,
          ),
      ],
    );
  }
}
