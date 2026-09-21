import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/agency.dart';
import 'package:realworth/core/theme/themes.dart';

/// WCAG relative-luminance contrast ratio between two opaque colours.
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // toDarkThemeData() builds its TextTheme via google_fonts, which reaches for
  // the asset bundle and needs the binding up.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Agency', () {
    test('slugs are unique', () {
      final slugs = Agency.all.map((a) => a.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    test('the house brand leads the list', () {
      expect(Agency.all.first, Agency.realWorth);
    });

    test('logo assets are derived from the slug', () {
      expect(Agency.realWorth.logoAsset, 'assets/images/agencies/realworth.png');
    });

    test('fromSlug resolves a known agency', () {
      expect(Agency.fromSlug('seeff').name, 'Seeff Property Group');
    });

    test('fromSlug falls back to the house brand', () {
      // A slug removed from the registry must not break a stored preference.
      expect(Agency.fromSlug('does-not-exist'), Agency.realWorth);
      expect(Agency.fromSlug(null), Agency.realWorth);
    });

    test('matchName finds an agency case-insensitively', () {
      expect(Agency.matchName('re/max')?.slug, 'remax');
      expect(Agency.matchName('Pam Golding')?.slug, 'pam-golding');
    });

    test('matchName returns null for an unlisted agency', () {
      // Null matters: the caller keeps the typed name rather than branding the
      // app as the wrong agency.
      expect(Agency.matchName('Bob Smith Realty'), isNull);
      expect(Agency.matchName(''), isNull);
      expect(Agency.matchName(null), isNull);
    });
  });

  group('RealEstateTheme.fromAgency', () {
    test('carries the agency palette', () {
      final theme = RealEstateTheme.fromAgency(Agency.fromSlug('remax'));
      expect(theme.primaryColor, Agency.fromSlug('remax').primaryColor);
      expect(theme.agency.slug, 'remax');
      expect(theme.brandName, 'RE/MAX');
    });

    test('keeps the shared editorial background across agencies', () {
      final house = RealEstateTheme.fromAgency(Agency.realWorth);
      final seeff = RealEstateTheme.fromAgency(Agency.fromSlug('seeff'));
      expect(seeff.backgroundColor, house.backgroundColor);
      expect(seeff.completeColor, house.completeColor);
    });

    test('a light brand keeps dark ink on its primary', () {
      final rawson = Agency.fromSlug('rawson');
      expect(RealEstateTheme.fromAgency(rawson).onPrimary, rawson.onPrimary);
    });

    test('every agency has readable ink over its primary', () {
      // Guards against a new entry defaulting to white ink over a pale brand.
      for (final agency in Agency.all) {
        final contrast = _contrastRatio(agency.primaryColor, agency.onPrimary);
        expect(
          contrast,
          greaterThan(4.5),
          reason: '${agency.name} ink fails WCAG AA over its primary',
        );
      }
    });

    test('dark variant lightens a dark brand for contrast', () {
      final agency = Agency.fromSlug('seeff');
      final dark = RealEstateTheme.fromAgencyDark(agency);
      expect(dark.primaryColor.computeLuminance(),
          greaterThan(agency.primaryColor.computeLuminance()));
    });

    test('dark variant darkens a very light brand', () {
      // Rawson's yellow would be unreadable if it were lightened further.
      final agency = Agency.fromSlug('rawson');
      final dark = RealEstateTheme.fromAgencyDark(agency);
      expect(dark.primaryColor.computeLuminance(),
          lessThan(agency.primaryColor.computeLuminance()));
    });

    test('dark theme data is built from the same agency', () {
      final theme = RealEstateTheme.fromAgency(Agency.fromSlug('rawson'));
      expect(theme.toDarkThemeData().colorScheme.primary,
          RealEstateTheme.fromAgencyDark(Agency.fromSlug('rawson')).primaryColor);
    });
  });
}
