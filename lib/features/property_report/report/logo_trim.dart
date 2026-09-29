import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// [bytes] with the plain border around the artwork cut off, so a square
/// logo tile (the mark small in the middle of a field of its colour) fills
/// the space it is drawn in. The border is whatever colour the corners share,
/// transparent included; a small margin is kept. Unchanged when the image
/// cannot be read or has no such border.
Uint8List trimLogoBorder(Uint8List bytes) {
  final img.Image? image;
  try {
    image = img.decodeImage(bytes);
  } catch (_) {
    return bytes;
  }
  if (image == null || image.width < 8 || image.height < 8) return bytes;

  // The border: the corner's colour, loosely, since logos saved from the
  // web carry grey compression noise in their white.
  final corner = image.getPixel(0, 0);
  bool plain(img.Pixel p) =>
      (corner.a < 16 && p.a < 16) ||
      ((p.r - corner.r).abs() < 48 &&
          (p.g - corner.g).abs() < 48 &&
          (p.b - corner.b).abs() < 48 &&
          (p.a - corner.a).abs() < 48);

  // A row or column is artwork when over 5% of it differs from the border,
  // so stray specks near the edge do not count.
  final rows = List.filled(image.height, 0);
  final cols = List.filled(image.width, 0);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (plain(image.getPixel(x, y))) continue;
      rows[y]++;
      cols[x]++;
    }
  }
  int first(List<int> counts, int length) =>
      counts.indexWhere((n) => n > 0.05 * length);
  int last(List<int> counts, int length) =>
      counts.lastIndexWhere((n) => n > 0.05 * length);
  final top = first(rows, image.width), bottom = last(rows, image.width);
  final left = first(cols, image.height), right = last(cols, image.height);
  if (top < 0 || left < 0) return bytes; // nothing but border
  final w = right - left + 1, h = bottom - top + 1;
  // Not worth it when the artwork already fills most of the image.
  if (w * h > image.width * image.height * 0.8) return bytes;

  final margin = (0.06 * (w > h ? w : h)).round();
  final x0 = (left - margin).clamp(0, image.width - 1);
  final y0 = (top - margin).clamp(0, image.height - 1);
  final x1 = (right + margin).clamp(0, image.width - 1);
  final y1 = (bottom + margin).clamp(0, image.height - 1);
  return img.encodePng(
    img.copyCrop(image, x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1),
  );
}
