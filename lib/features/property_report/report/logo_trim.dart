import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// [bytes] with the plain border around the artwork cut off, so a square
/// logo tile (the mark small in the middle of a field of its colour) fills
/// the space it is drawn in. The border is whatever colour the corners share,
/// transparent included; a small margin is kept. Unchanged when the image
/// cannot be read or has no such border.
Uint8List trimLogoBorder(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null || image.width < 8 || image.height < 8) return bytes;

  final corner = image.getPixel(0, 0);
  bool plain(img.Pixel p) =>
      (corner.a < 16 && p.a < 16) ||
      ((p.r - corner.r).abs() < 24 &&
          (p.g - corner.g).abs() < 24 &&
          (p.b - corner.b).abs() < 24 &&
          (p.a - corner.a).abs() < 24);

  var top = image.height, bottom = -1, left = image.width, right = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (plain(image.getPixel(x, y))) continue;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
      if (x < left) left = x;
      if (x > right) right = x;
    }
  }
  if (bottom < 0) return bytes; // nothing but border
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
