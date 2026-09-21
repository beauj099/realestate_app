import 'package:flutter/material.dart';

/// A white-label agency brand.
///
/// Each agency supplies the palette the app re-themes itself with once an agent
/// picks it. Logos live at `assets/images/agencies/<slug>.png`; where a file is
/// absent, [AgencyLogo] falls back to the [monogram] mark so nothing renders
/// broken.
///
/// Colours are sampled from each supplied logo rather than guessed, so the app
/// chrome matches the artwork beside it.
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

  /// Where this agency's logo is expected to live.
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
  /// Listed after the house brand and otherwise alphabetical. Only add artwork
  /// you have the right to distribute; these are third-party trademarks.
  static const List<Agency> all = [
    realWorth,
    Agency(
      slug: 'acutts',
      name: 'Acutts Real Estate',
      monogram: 'AC',
      primaryColor: Color(0xFF00447C),
      secondaryColor: Color(0xFFE30613),
    ),
    Agency(
      slug: 'century-21',
      name: 'Century 21',
      monogram: 'C21',
      // The current identity is black with a gold accent, not the older gold.
      primaryColor: Color(0xFF1C1C1C),
      secondaryColor: Color(0xFFB0985E),
    ),
    Agency(
      slug: 'chas-everitt',
      name: 'Chas Everitt',
      monogram: 'CE',
      primaryColor: Color(0xFF245490),
      secondaryColor: Color(0xFFF5A623),
    ),
    Agency(
      slug: 'engel-volkers',
      name: 'Engel & Völkers',
      monogram: 'EV',
      primaryColor: Color(0xFFE40000),
      secondaryColor: Color(0xFF242424),
    ),
    Agency(
      slug: 'harcourts',
      name: 'Harcourts',
      monogram: 'HC',
      primaryColor: Color(0xFF002049),
      secondaryColor: Color(0xFF00AAE6),
    ),
    Agency(
      slug: 'jawitz',
      name: 'Jawitz Properties',
      monogram: 'JP',
      // Supplied logo is monochrome, so the palette follows the known brand.
      primaryColor: Color(0xFF0033A0),
      secondaryColor: Color(0xFFE4002B),
    ),
    Agency(
      slug: 'just-property',
      name: 'Just Property',
      monogram: 'JP',
      primaryColor: Color(0xFF093C71),
      secondaryColor: Color(0xFFF0CC3C),
    ),
    Agency(
      slug: 'keller-williams',
      name: 'Keller Williams',
      monogram: 'KW',
      primaryColor: Color(0xFFB41F25),
      secondaryColor: Color(0xFF1E1E1E),
    ),
    Agency(
      slug: 'leapfrog',
      name: 'Leapfrog Property Group',
      monogram: 'LF',
      // Lime is too light to carry white text.
      primaryColor: Color(0xFFC2D83E),
      secondaryColor: Color(0xFF303030),
      onPrimary: Color(0xFF1E1E1E),
    ),
    Agency(
      slug: 'lew-geffen',
      name: "Lew Geffen Sotheby's International Realty",
      monogram: 'LG',
      primaryColor: Color(0xFF0C183C),
      secondaryColor: Color(0xFFB0985E),
    ),
    Agency(
      slug: 'meridian',
      name: 'Meridian Realty',
      monogram: 'MR',
      primaryColor: Color(0xFF123368),
      secondaryColor: Color(0xFFF5A623),
    ),
    Agency(
      slug: 'pam-golding',
      name: 'Pam Golding Properties',
      monogram: 'PG',
      primaryColor: Color(0xFF014423),
      secondaryColor: Color(0xFFB8975A),
    ),
    Agency(
      slug: 'property-coza',
      name: 'Property.CoZa',
      monogram: 'PC',
      primaryColor: Color(0xFF991B1E),
      secondaryColor: Color(0xFF1E1E1E),
    ),
    Agency(
      slug: 'quay-1',
      name: 'Quay 1 International Realty',
      monogram: 'Q1',
      primaryColor: Color(0xFF3C5AA5),
      secondaryColor: Color(0xFFFCC000),
    ),
    Agency(
      slug: 'rawson',
      name: 'Rawson Property Group',
      monogram: 'RP',
      // Rawson's identity is the yellow, which needs dark ink over it.
      primaryColor: Color(0xFFFED404),
      secondaryColor: Color(0xFFE6281E),
      onPrimary: Color(0xFF181818),
    ),
    Agency(
      slug: 'realtors-international',
      name: 'Realtors International',
      monogram: 'RI',
      primaryColor: Color(0xFF071F45),
      secondaryColor: Color(0xFFB0985E),
    ),
    Agency(
      slug: 'remax',
      name: 'RE/MAX',
      monogram: 'RM',
      primaryColor: Color(0xFF003DA5),
      secondaryColor: Color(0xFFD81824),
    ),
    Agency(
      slug: 'seeff',
      name: 'Seeff Property Group',
      monogram: 'SF',
      primaryColor: Color(0xFF17214B),
      secondaryColor: Color(0xFFB41824),
    ),
    Agency(
      slug: 'sothebys',
      name: "Sotheby's International Realty",
      monogram: 'SIR',
      primaryColor: Color(0xFF002454),
      secondaryColor: Color(0xFFB0985E),
    ),
    Agency(
      slug: 'tyson',
      name: 'Tyson Properties',
      monogram: 'TP',
      primaryColor: Color(0xFF002E2E),
      secondaryColor: Color(0xFFC9A227),
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
