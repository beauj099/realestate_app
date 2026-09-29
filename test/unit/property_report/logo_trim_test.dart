import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:realworth/features/property_report/report/logo_trim.dart';

void main() {
  test('cuts the plain border around a logo tile, keeping a small margin', () {
    // A 200 x 200 tile in the brand colour with 100 x 40 of artwork in the middle.
    final tile = img.Image(width: 200, height: 200)
      ..clear(img.ColorRgb8(254, 212, 4));
    img.fillRect(
      tile,
      x1: 50,
      y1: 80,
      x2: 149,
      y2: 119,
      color: img.ColorRgb8(24, 24, 24),
    );

    final trimmed = img.decodePng(trimLogoBorder(img.encodePng(tile)))!;

    expect(trimmed.width, 112); // 100 + 6% margin each side
    expect(trimmed.height, 52);
  });

  test('leaves a logo that already fills its image alone', () {
    final full = img.Image(width: 100, height: 40)
      ..clear(img.ColorRgb8(24, 24, 24));
    final bytes = img.encodePng(full);
    expect(trimLogoBorder(bytes), same(bytes));
  });
}
