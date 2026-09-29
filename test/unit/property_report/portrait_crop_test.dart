import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:realworth/features/property_report/report/portrait_crop.dart';

void main() {
  test('a portrait becomes a square from just below the top', () {
    final portrait = img.Image(width: 200, height: 300)
      ..clear(img.ColorRgb8(200, 200, 200));
    final square = img.decodeJpg(headAndShoulders(img.encodeJpg(portrait)))!;
    expect(square.width, 170);
    expect(square.height, 170);
  });

  test('unreadable bytes come back unchanged', () {
    final junk = img.encodePng(img.Image(width: 1, height: 1)).sublist(0, 5);
    expect(headAndShoulders(junk), same(junk));
  });
}
