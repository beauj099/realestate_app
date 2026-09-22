import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/agency.dart';

void main() {
  final bay = Agency.custom(slug: 'custom-1', name: 'Bay Realty');

  test('a custom agency wears the house palette with initials', () {
    expect(bay.primaryColor, Agency.realWorth.primaryColor);
    expect(bay.monogram, 'BR');
    expect(bay.isCustom, isTrue);
    expect(Agency.realWorth.isCustom, isFalse);
  });

  test('round-trips through JSON and still compares equal', () {
    final withLogo = Agency.custom(
      slug: 'custom-2',
      name: 'Coast Homes',
      logoFilePath: '/data/logo.png',
    );
    expect(Agency.customFromJson(withLogo.toJson()), withLogo);
  });

  test('a new logo makes it a different value', () {
    final a = Agency.custom(slug: 'custom-3', name: 'X', logoFilePath: 'a');
    final b = Agency.custom(slug: 'custom-3', name: 'X', logoFilePath: 'b');
    expect(a == b, isFalse);
  });

  test('resolves by slug and by exact name', () {
    expect(Agency.fromSlug('custom-1', custom: [bay]), bay);
    expect(Agency.matchName('bay realty', custom: [bay]), bay);
  });

  test('only an uploaded logo puts the banner on white', () {
    expect(bay.bannerColor, bay.primaryColor);
    final withLogo = Agency.custom(
      slug: 'custom-4',
      name: 'Y',
      logoFilePath: 'y.png',
    );
    expect(withLogo.bannerColor, const Color(0xFFFFFFFF));
  });

  test('monogramFor takes up to two initials', () {
    expect(Agency.monogramFor('Bay'), 'B');
    expect(Agency.monogramFor('  one two three '), 'OT');
    expect(Agency.monogramFor(''), '?');
  });

  test('the house brand draws its bundled logo, not a monogram', () {
    expect(Agency.realWorth.imageAsset, 'assets/images/logo.jpg');
    expect(Agency.fromSlug('acutts').imageAsset, isNull);
    expect(
      Agency.fromSlug('remax').imageAsset,
      'assets/images/agencies/remax.png',
    );
  });
}
