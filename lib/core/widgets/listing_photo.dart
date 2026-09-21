import 'package:flutter/material.dart';

import '../theme/themes.dart';
import 'platform_image.dart';

/// Renders a property photo from either a remote URL or a local file path.
///
/// Photos captured on device are local paths until an upload endpoint exists,
/// while photos loaded back from the API are URLs. Callers should not have to
/// care which, so this picks the right loader and shows the same placeholder
/// either way.
Widget listingPhoto(
  String? path, {
  required RealEstateTheme theme,
  required TextTheme textTheme,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
}) {
  if (path == null || path.isEmpty) {
    return _placeholder(theme, textTheme, Icons.home_outlined, null);
  }

  Widget onError(BuildContext context, Object error, StackTrace? stack) =>
      _placeholder(theme, textTheme, Icons.broken_image_outlined, 'Unavailable');

  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: onError,
    );
  }
  return localFileImage(
    path,
    fit: fit,
    cacheWidth: cacheWidth,
    errorBuilder: onError,
  );
}

Widget _placeholder(
  RealEstateTheme theme,
  TextTheme textTheme,
  IconData icon,
  String? label,
) {
  return Container(
    color: theme.imagePlaceholder,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.mutedIcon, size: 26),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: theme.mutedIcon),
          ),
        ],
      ],
    ),
  );
}
