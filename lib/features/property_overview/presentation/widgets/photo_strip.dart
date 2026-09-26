import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/photo_urls.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/listing_photo.dart';
import '../../../../core/widgets/real_estate_dialog.dart';

/// A picked photo, with its bytes cached for the web (where the path is only
/// a blob URL).
typedef PickedShot = ({String path, Uint8List? bytes, String? filename});

/// Longest side and JPEG quality photos are saved at: sharp on any phone or
/// report, and roughly a third of the upload size of 2000px at 85.
const double _maxWidth = 1600;
const int _quality = 80;

/// Asks camera or gallery, then returns up to [remaining] photos. The gallery
/// allows picking several at once; the camera takes one.
Future<List<PickedShot>> pickPhotos({
  required BuildContext context,
  required RealEstateTheme theme,
  required int remaining,
}) async {
  if (remaining <= 0) return const [];
  final source = await showRealEstateBottomSheet<ImageSource>(
    context: context,
    theme: theme,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                remaining == 1
                    ? 'Choose from gallery'
                    : 'Choose from gallery (up to $remaining)',
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return const [];

  final picker = ImagePicker();
  final List<XFile> picked;
  if (source == ImageSource.camera) {
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: _quality,
      maxWidth: _maxWidth,
    );
    picked = shot == null ? const [] : [shot];
  } else if (remaining == 1) {
    final shot = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: _quality,
      maxWidth: _maxWidth,
    );
    picked = shot == null ? const [] : [shot];
  } else {
    picked = await picker.pickMultiImage(
      imageQuality: _quality,
      maxWidth: _maxWidth,
      limit: remaining,
    );
  }

  if (picked.length > remaining && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Only $remaining more ${remaining == 1 ? 'photo fits' : 'photos fit'}'
          ' — the first $remaining were added.',
        ),
      ),
    );
  }
  return [
    for (final x in picked.take(remaining))
      (path: x.path, bytes: await x.readAsBytes(), filename: x.name),
  ];
}

/// What the agent chose for one photo.
enum PhotoAction { makeFirst, remove }

/// Options for one photo: make it the main/cover photo (unless it already
/// is) or remove it.
Future<PhotoAction?> showPhotoActions({
  required BuildContext context,
  required RealEstateTheme theme,
  required bool isFirst,
  required String firstLabel,
}) {
  return showRealEstateBottomSheet<PhotoAction>(
    context: context,
    theme: theme,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            if (!isFirst)
              ListTile(
                leading: Icon(Icons.star_outline, color: theme.primaryColor),
                title: Text('Make $firstLabel'),
                onTap: () => Navigator.pop(sheetContext, PhotoAction.makeFirst),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.error),
              title: Text('Remove photo', style: TextStyle(color: theme.error)),
              onTap: () => Navigator.pop(sheetContext, PhotoAction.remove),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A horizontal strip of photos the agent reorders by holding one and
/// dragging it. The first photo carries [firstBadge] (MAIN / COVER); tapping
/// a photo calls [onTap]. A photo not yet on the server shows an upload mark.
class ReorderablePhotoStrip extends StatelessWidget {
  final List<String> paths;
  final String baseUrl;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final double tileWidth;
  final double tileHeight;
  final String firstBadge;
  final ValueChanged<List<String>> onReorder;
  final ValueChanged<String> onTap;

  /// Shown after the photos, e.g. an "Add" tile. Not draggable.
  final Widget? trailing;

  const ReorderablePhotoStrip({
    super.key,
    required this.paths,
    required this.baseUrl,
    required this.theme,
    required this.textTheme,
    required this.firstBadge,
    required this.onReorder,
    required this.onTap,
    this.tileWidth = 120,
    this.tileHeight = 110,
    this.trailing,
  });

  static const double _gap = 10;

  // newIndex is already adjusted for the removed item (onReorderItem).
  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex == oldIndex) return;
    final order = List.of(paths);
    order.insert(newIndex, order.removeAt(oldIndex));
    onReorder(order);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tileHeight,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        // Detached from the PrimaryScrollController: the strip sits inside a
        // vertical scroll view.
        primary: false,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: paths.length,
        onReorderItem: _handleReorder,
        footer: trailing,
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.06 * Curves.easeOut.transform(animation.value),
            child: Material(
              elevation: 8 * animation.value,
              color: Colors.transparent,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
          ),
          child: child,
        ),
        itemBuilder: (context, index) {
          final path = paths[index];
          return Padding(
            key: ValueKey(path),
            padding: const EdgeInsets.only(right: _gap),
            // Long-press to drag, so a plain tap still opens the options and
            // a swipe still scrolls the strip.
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: _PhotoTile(
                path: path,
                isFirst: index == 0,
                badge: firstBadge,
                width: tileWidth,
                height: tileHeight,
                baseUrl: baseUrl,
                theme: theme,
                textTheme: textTheme,
                onTap: () => onTap(path),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final bool isFirst;
  final String badge;
  final double width;
  final double height;
  final String baseUrl;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.path,
    required this.isFirst,
    required this.badge,
    required this.width,
    required this.height,
    required this.baseUrl,
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = !isRemotePhoto(path);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFirst ? theme.primaryColor : theme.borderLight,
            width: isFirst ? 2.5 : 1,
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
              cacheWidth: 400,
              baseUrl: baseUrl,
            ),
            if (isFirst)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: textTheme.labelSmall?.copyWith(
                      color: theme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            if (pending)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    size: 14,
                    color: Colors.white,
                    semanticLabel: 'Not uploaded yet',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Add" tile closing a photo strip.
class AddPhotoTile extends StatelessWidget {
  final double width;
  final double height;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const AddPhotoTile({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.onTap,
    this.width = 96,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
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

/// Small grey hint under a strip explaining drag and tap.
class PhotoStripHint extends StatelessWidget {
  final String text;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const PhotoStripHint({
    super.key,
    required this.text,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.open_with, size: 14, color: theme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: theme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
