import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A square head-and-shoulders crop of a profile photo, for a round frame.
/// A round frame on the whole photo cuts the top of the head off a portrait
/// and fills the bottom with shoulders; profile photos have the face in the
/// upper part, so this takes 85% of the width from just below the top.
/// Unchanged when the image cannot be read, or is already square: the agent
/// framed it in the circle when uploading it (`cropToCircle`).
Uint8List headAndShoulders(Uint8List bytes) {
  final img.Image? photo;
  try {
    photo = img.decodeImage(bytes);
  } catch (_) {
    return bytes;
  }
  if (photo == null || (photo.width - photo.height).abs() <= 2) return bytes;
  final side =
      (0.85 * (photo.width < photo.height ? photo.width : photo.height))
          .round();
  final x = ((photo.width - side) / 2).round();
  // Portraits: a little headroom above the hair. Landscape: centred.
  final y = photo.height > photo.width
      ? (0.04 * photo.height).round().clamp(0, photo.height - side)
      : ((photo.height - side) / 2).round();
  return img.encodeJpg(
    img.copyCrop(photo, x: x, y: y, width: side, height: side),
    quality: 90,
  );
}
