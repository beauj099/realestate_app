import 'package:flutter/material.dart';

/// A white-label agency brand.
///
/// Each agency supplies the palette the app re-themes itself with once an agent
/// picks it. Logos are optional: [logoAsset] points at a file the brand owner
/// drops into `assets/images/agencies/`, and until that file exists the UI
/// falls back to the [monogram] mark so nothing renders broken.
class Agency {
  /// Stable identifier persisted in preferences and sent to the backend.
  final String slug;

  /// Full name shown in the picker.
  final String name;

  /// Short mark drawn when no logo file is present.
  final String monogram;

  /// Brand primary — app bars, buttons, selected states.
  final Color primaryColor;

  /// Brand secondary/accent.
  final Color secondaryColor;

  /// Ink used on top of [primaryColor]. Light brands need dark ink.
  final Color onPrimary;

  const Agency({
    required this.slug,
    required this.name,
    required this.monogram,
    required this.primaryColor,
    required this.secondaryColor,
    this.onPrimary = Colors.white,
  });

  /// Where this agency's logo is expected to live once supplied.
  String get logoAsset => 'assets/images/agencies/$slug.png';

  /// The house brand — used when an agent has not picked an agency.
  static const Agency realWorth = Agency(
    slug: 'realworth',
    name: 'RealWorth',
    monogram: 'RW',
    primaryColor: Color(0xFF1B365D),
    secondaryColor: Color(0xFF1E1E1E),
  );

  /// South African agencies an agent can white-label the app with.
  ///
  /// Colours are approximations of each brand's public palette and are only
  /// applied to this app's own chrome. Logo files are supplied by the brand
  /// owner; none are committed here.
  static const List<Agency> all = [
    realWorth,
    Agency(
      slug: 'remax',
      name: 'RE/MAX',
      monogram: 'RM',
      primaryColor: Color(0xFF003DA5),
      secondaryColor: Color(0xFFDC1C2E),
    ),
    Agency(
      slug: 'pam-golding',
      name: 'Pam Golding Properties',
      monogram: 'PG',
      primaryColor: Color(0xFF00573F),
      secondaryColor: Color(0xFFB8975A),
    ),
    Agency(
      slug: 'seeff',
      name: 'Seeff Property Group',
      monogram: 'SF',
      primaryColor: Color(0xFF00305B),
      secondaryColor: Color(0xFFE2001A),
    ),
    Agency(
      slug: 'rawson',
      name: 'Rawson Property Group',
      monogram: 'RW',
      primaryColor: Color(0xFF00447C),
      secondaryColor: Color(0xFF8DC63F),
    ),
    Agency(
      slug: 'chas-everitt',
      name: 'Chas Everitt',
      monogram: 'CE',
      primaryColor: Color(0xFF002F6C),
      secondaryColor: Color(0xFFF5A623),
    ),
    Agency(
      slug: 'keller-williams',
      name: 'Keller Williams',
      monogram: 'KW',
      primaryColor: Color(0xFFC8102E),
      secondaryColor: Color(0xFF1E1E1E),
    ),
    Agency(
      slug: 'tyson',
      name: 'Tyson Properties',
      monogram: 'TP',
      primaryColor: Color(0xFF6A1B32),
      secondaryColor: Color(0xFFC9A227),
    ),
    Agency(
      slug: 'engel-volkers',
      name: 'Engel & Völkers',
      monogram: 'EV',
      primaryColor: Color(0xFFED1C24),
      secondaryColor: Color(0xFF1E1E1E),
    ),
    Agency(
      slug: 'harcourts',
      name: 'Harcourts',
      monogram: 'HC',
      primaryColor: Color(0xFF00529B),
      secondaryColor: Color(0xFF7AB800),
    ),
    Agency(
      slug: 'century-21',
      name: 'Century 21',
      monogram: 'C21',
      primaryColor: Color(0xFFBEAF87),
      secondaryColor: Color(0xFF252526),
      onPrimary: Color(0xFF1E1E1E),
    ),
    Agency(
      slug: 'jawitz',
      name: 'Jawitz Properties',
      monogram: 'JP',
      primaryColor: Color(0xFF0033A0),
      secondaryColor: Color(0xFFE4002B),
    ),
    Agency(
      slug: 'acutts',
      name: 'Acutts Real Estate',
      monogram: 'AC',
      primaryColor: Color(0xFF00447C),
      secondaryColor: Color(0xFFE30613),
    ),
  ];

  /// Resolves a stored [slug] back to an agency, falling back to the house
  /// brand when the slug is unknown (e.g. removed from the registry).
  static Agency fromSlug(String? slug) {
    if (slug == null) return realWorth;
    return all.firstWhere((a) => a.slug == slug, orElse: () => realWorth);
  }

  /// Best-effort match of a free-text agency name typed at registration.
  ///
  /// Returns `null` when nothing matches so callers can keep the typed name
  /// without silently branding the app as the wrong agency.
  static Agency? matchName(String? name) {
    final needle = name?.trim().toLowerCase();
    if (needle == null || needle.isEmpty) return null;
    for (final agency in all) {
      final haystack = agency.name.toLowerCase();
      if (haystack == needle ||
          haystack.contains(needle) ||
          needle.contains(haystack)) {
        return agency;
      }
    }
    return null;
  }
}
