import 'package:flutter/material.dart';

import '../../../../core/network/run_limited.dart';
import '../../../../core/theme/themes.dart';
import '../../providers/property_provider.dart';
import 'photo_strip.dart';

/// Exterior shots of the property, with one nominated as the main image.
///
/// The main photo is what identifies the listing at a glance on the home
/// screen — a photo of the house says more than a reference number ever will.
/// The first photo is the main one; the agent reorders by holding and
/// dragging, or taps a photo to make it the main one. Photos upload as soon as
/// they are picked, and the order is saved with them.
class ExteriorPhotosSection extends StatelessWidget {
  final List<String> photos;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final PropertyViewModel viewModel;

  /// Backend root used to resolve app-relative `/uploads/...` photo paths.
  final String baseUrl;

  const ExteriorPhotosSection({
    super.key,
    required this.photos,
    required this.theme,
    required this.textTheme,
    required this.viewModel,
    this.baseUrl = '',
  });

  static const int _max = PropertyViewModel.maxExteriorPhotos;

  int get _remaining => _max - photos.length;

  Future<void> _addPhotos(BuildContext context) async {
    final shots = await pickPhotos(
      context: context,
      theme: theme,
      remaining: _remaining,
    );
    if (shots.isEmpty) return;
    // Show every shot straight away, then upload them one by one.
    for (final shot in shots) {
      viewModel.addExteriorPhoto(
        shot.path,
        bytes: shot.bytes,
        filename: shot.filename,
      );
    }
    // Three at a time, then save the order: parallel uploads reach the
    // server in whatever order they finish.
    final results = await runLimited(width: 3, [
      for (final shot in shots) () => viewModel.uploadExteriorPhoto(shot.path),
    ]);
    final failed = results.where((ok) => !ok).length;
    if (shots.length > 1 || photos.isNotEmpty) {
      await viewModel.saveExteriorOrder();
    }
    if (failed > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 1
                ? "1 photo couldn't upload yet. It retries when you save "
                      'the property.'
                : "$failed photos couldn't upload yet. They retry when you "
                      'save the property.',
          ),
        ),
      );
    }
  }

  Future<void> _photoActions(BuildContext context, String path) async {
    final action = await showPhotoActions(
      context: context,
      theme: theme,
      isFirst: photos.isNotEmpty && photos.first == path,
      firstLabel: 'main photo',
    );
    if (action == PhotoAction.makeFirst) viewModel.setMainExteriorPhoto(path);
    if (action == PhotoAction.remove) viewModel.removeExteriorPhoto(path);
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
              Text(
                '${photos.length} / $_max',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          _EmptyPhotoPrompt(
            theme: theme,
            textTheme: textTheme,
            onTap: () => _addPhotos(context),
          )
        else ...[
          ReorderablePhotoStrip(
            paths: photos,
            baseUrl: baseUrl,
            theme: theme,
            textTheme: textTheme,
            firstBadge: 'MAIN',
            tileWidth: 150,
            tileHeight: 132,
            onReorder: (order) => viewModel.reorderExteriorPhotos(order),
            onTap: (path) => _photoActions(context, path),
            trailing: _remaining > 0
                ? AddPhotoTile(
                    theme: theme,
                    textTheme: textTheme,
                    height: 132,
                    onTap: () => _addPhotos(context),
                  )
                : null,
          ),
          if (photos.length > 1)
            PhotoStripHint(
              text:
                  'Hold and drag to reorder. Tap a photo to make it the main one.',
              theme: theme,
              textTheme: textTheme,
            ),
        ],
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
              'Add property photos',
              style: textTheme.titleMedium?.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Up to ${ExteriorPhotosSection._max} — the first is the main photo',
              style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
