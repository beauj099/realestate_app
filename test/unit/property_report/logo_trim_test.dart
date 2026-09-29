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

  test('ignores light-grey noise and stray specks in a white border', () {
    // A web thumbnail: a navy box on white with compression noise around it.
    final tile = img.Image(width: 160, height: 160)
      ..clear(img.ColorRgb8(255, 255, 255));
    for (var i = 0; i < 160; i += 7) {
      tile.setPixel(i, 3, img.ColorRgb8(232, 232, 232)); // grey noise
      tile.setPixel(3, i, img.ColorRgb8(236, 236, 236));
    }
    tile.setPixel(150, 150, img.ColorRgb8(90, 90, 90)); // one dark speck
    img.fillRect(
      tile,
      x1: 10,
      y1: 50,
      x2: 149,
      y2: 109,
      color: img.ColorRgb8(0, 36, 84),
    );

    final trimmed = img.decodePng(trimLogoBorder(img.encodePng(tile)))!;

    // The box (140 x 60) plus 6% of 140 on each side, within the image.
    expect(trimmed.height, lessThan(80));
    expect(trimmed.width, lessThanOrEqualTo(160));
  });

  test('leaves a logo that already fills its image alone', () {
    final full = img.Image(width: 100, height: 40)
      ..clear(img.ColorRgb8(24, 24, 24));
    final bytes = img.encodePng(full);
    expect(trimLogoBorder(bytes), same(bytes));
  });
}
