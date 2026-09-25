import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/agency.dart';

void main() {
  group('Agency.fromApi', () {
    test('reads a listed agency and keeps its bundled logo as fallback', () {
      final remax = Agency.fromApi({
        'slug': 'remax',
        'name': 'RE/MAX',
        'monogram': 'RM',
        'primaryColor': '#003DA5',
        'secondaryColor': '#D81824',
        'onPrimaryColor': '#FFFFFF',
        'bannerColor': '#FFFFFF',
        'logoUrl': 'https://cdn.example/agencies/remax.png',
        'isCustom': false,
      });
      expect(remax.primaryColor, const Color(0xFF003DA5));
      expect(remax.bannerColor, const Color(0xFFFFFFFF));
      expect(remax.logoUrl, 'https://cdn.example/agencies/remax.png');
      expect(remax.imageAsset, 'assets/images/agencies/remax.png');
      expect(remax.isCustom, isFalse);
    });

    test('an agency only the API knows has no bundled file', () {
      final era = Agency.fromApi({
        'slug': 'era',
        'name': 'ERA South Africa',
        'monogram': 'ERA',
        'primaryColor': '#25205F',
        'logoUrl': 'https://cdn.example/agencies/era.png',
      });
      expect(era.imageAsset, isNull);
      expect(era.bannerColor, era.primaryColor);
      expect(era.secondaryColor, Agency.realWorth.secondaryColor);
    });

    test('an agent-added agency wears the house palette, logo on white', () {
      final bay = Agency.fromApi({
        'slug': 'custom-bay-realty',
        'name': 'Bay Realty',
        'monogram': 'BR',
        'logoUrl': 'https://cdn.example/agencies/custom-bay-realty-1.png',
        'isCustom': true,
      });
      expect(bay.isCustom, isTrue);
      expect(bay.primaryColor, Agency.realWorth.primaryColor);
      expect(bay.bannerColor, const Color(0xFFFFFFFF));
    });

    test('replaces unreadable text colours with legible ink', () {
      final orange = Agency.fromApi({
        'slug': 'x',
        'name': 'X',
        'primaryColor': '#F7841C',
        'onPrimaryColor': '#FFFFFF',
      });
      expect(orange.onPrimary, const Color(0xFF1E1E1E));
      final navy = Agency.fromApi({
        'slug': 'y',
        'name': 'Y',
        'primaryColor': '#0C0C54',
      });
      expect(navy.onPrimary, const Color(0xFFFFFFFF));
    });

    test('round-trips through the cache shape unchanged', () {
      for (final agency in Agency.all) {
        expect(Agency.fromApi(agency.toApiJson()), agency, reason: agency.slug);
      }
      final custom = Agency.custom(
        slug: 'custom-a',
        name: 'A Homes',
        logoUrl: 'https://cdn.example/a.png',
      );
      expect(Agency.fromApi(custom.toApiJson()), custom);
    });

    test('a restyle is a different value, so the theme follows', () {
      final before = Agency.fromSlug('seeff');
      final after = Agency.fromApi({
        ...before.toApiJson(),
        'primaryColor': '#000000',
      });
      expect(after == before, isFalse);
    });
  });

  test('parseHexColor accepts only #RRGGBB', () {
    expect(Agency.parseHexColor('#1b365d'), const Color(0xFF1B365D));
    expect(Agency.parseHexColor('1B365D'), isNull);
    expect(Agency.parseHexColor('#FFF'), isNull);
    expect(Agency.parseHexColor(null), isNull);
    expect(Agency.hexOf(const Color(0xFF1B365D)), '#1B365D');
  });

  test('matchName prefers an exact agent-added name in the directory', () {
    final bay = Agency.custom(slug: 'custom-bay', name: 'Bay Realty');
    final era = Agency.fromApi({
      'slug': 'era',
      'name': 'ERA South Africa',
      'primaryColor': '#25205F',
    });
    final directory = [...Agency.all, era, bay];
    expect(Agency.matchName('bay realty', agencies: directory), bay);
    expect(Agency.matchName('ERA South Africa', agencies: directory), era);
    expect(Agency.fromSlug('era', agencies: directory), era);
    // A custom name is never a fuzzy match for something longer.
    expect(Agency.matchName('Bay Realty Durban', agencies: directory), isNull);
  });
}
