import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A white-label agency brand.
///
/// Each agency supplies the palette the app re-themes itself with once an agent
/// picks it. The list comes from `GET /api/agencies` (see
/// `agency_directory.dart`), so agencies can be added or restyled without an
/// app release; [all] is the bundled copy used until the API answers or when
/// it cannot be reached. Logos come from [logoUrl] (R2), falling back to
/// `assets/images/agencies/<slug>.png` and then to the [monogram] mark, so
/// nothing renders broken.
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

  /// Whether `assets/images/agencies/<slug>.png` is bundled.
  ///
  /// RealWorth has no file here (its logo is [assetOverride]), and agencies
  /// that only exist in the API have none; those fall back to [logoUrl] or a
  /// monogram tile (see `assets/images/agencies/README.md`).
  /// [AgencyLogo] checks this first so it never issues an [Image.asset]
  /// fetch for a file that cannot exist — on web that fetch logs a 404
  /// ("assets/assets/images/agencies/`<slug>`.png") even though the
  /// `errorBuilder` fallback still draws correctly.
  final bool hasLogoFile;

  /// Bundled image to draw instead of [logoAsset], for a brand whose artwork
  /// lives outside the agencies folder (the house logo).
  final String? assetOverride;

  /// Logo an agent uploaded for an agency they added themselves. A path on
  /// this device, so only set on [isCustom] agencies not yet sent to the API.
  final String? logoFilePath;

  /// The logo served by the API (an R2 URL). Preferred over the bundled file,
  /// so a logo can change without an app release.
  final String? logoUrl;

  /// Fill behind the logo where it is drawn larger than a tile, e.g. the home
  /// header. Matches the logo artwork's own background so the logo reads as
  /// filling the panel; defaults to [primaryColor], which most tiles use.
  final Color? _bannerColor;

  const Agency({
    required this.slug,
    required this.name,
    required this.monogram,
    required this.primaryColor,
    required this.secondaryColor,
    this.onPrimary = Colors.white,
    this.hasLogoFile = true,
    this.assetOverride,
    this.logoFilePath,
    this.logoUrl,
    Color? bannerColor,
  }) : _bannerColor = bannerColor;

  /// An agency the agent added via "Other", worn with the house palette —
  /// there is no brand to theme from, and guessed colours would look broken.
  factory Agency.custom({
    required String slug,
    required String name,
    String? monogram,
    String? logoFilePath,
    String? logoUrl,
  }) {
    final hasLogo = logoFilePath != null || logoUrl != null;
    return Agency(
      slug: slug,
      name: name,
      monogram: monogram ?? monogramFor(name),
      primaryColor: realWorth.primaryColor,
      secondaryColor: realWorth.secondaryColor,
      hasLogoFile: false,
      logoFilePath: logoFilePath,
      logoUrl: logoUrl,
      // Uploaded logos are drawn on white; without one the monogram tile
      // carries the house colour.
      bannerColor: hasLogo ? Colors.white : null,
    );
  }

  /// An agency as `GET /api/agencies` returns it.
  ///
  /// Null colours mean the house palette (agent-added agencies have none). A
  /// listed agency keeps its bundled logo file as the offline fallback. If the
  /// text colour sent would be hard to read on the primary, the more legible
  /// of dark and white ink is used instead.
  factory Agency.fromApi(Map<String, dynamic> json) {
    final slug = json['slug'] as String;
    final name = json['name'] as String;
    final monogram = json['monogram'] as String?;
    final logoUrl = json['logoUrl'] as String?;
    final primary = parseHexColor(json['primaryColor']);
    if (json['isCustom'] == true || primary == null) {
      return Agency.custom(
        slug: slug,
        name: name,
        monogram: monogram,
        logoUrl: logoUrl,
      );
    }
    final bundled = all.where((a) => a.slug == slug).firstOrNull;
    return Agency(
      slug: slug,
      name: name,
      monogram: monogram ?? monogramFor(name),
      primaryColor: primary,
      secondaryColor:
          parseHexColor(json['secondaryColor']) ?? realWorth.secondaryColor,
      onPrimary: legibleInk(primary, parseHexColor(json['onPrimaryColor'])),
      hasLogoFile: bundled?.hasLogoFile ?? false,
      assetOverride: bundled?.assetOverride,
      logoUrl: logoUrl,
      bannerColor: parseHexColor(json['bannerColor']),
    );
  }

  /// The API shape, for caching the directory on the device.
  Map<String, dynamic> toApiJson() => {
    'slug': slug,
    'name': name,
    'monogram': monogram,
    'primaryColor': isCustom ? null : hexOf(primaryColor),
    'secondaryColor': isCustom ? null : hexOf(secondaryColor),
    'onPrimaryColor': isCustom ? null : hexOf(onPrimary),
    'bannerColor': isCustom || _bannerColor == null
        ? null
        : hexOf(_bannerColor),
    'logoUrl': logoUrl,
    'isCustom': isCustom,
  };

  /// "#1B365D" -> colour; null for anything else.
  static Color? parseHexColor(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value.trim());
    if (match == null) return null;
    return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
  }

  /// Colour -> "#1B365D".
  static String hexOf(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// [preferred] when it reads clearly (WCAG AA, 4.5:1) on [background],
  /// otherwise whichever of near-black and white contrasts more.
  static Color legibleInk(Color background, Color? preferred) {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    if (preferred != null && ratio(background, preferred) >= 4.5) {
      return preferred;
    }
    const dark = Color(0xFF1E1E1E);
    return ratio(background, dark) >= ratio(background, Colors.white)
        ? dark
        : Colors.white;
  }

  /// Prefix of every [Agency.custom] slug.
  static const String customSlugPrefix = 'custom-';

  bool get isCustom => slug.startsWith(customSlugPrefix);

  Color get bannerColor => _bannerColor ?? primaryColor;

  /// Where this agency's logo is expected to live.
  String get logoAsset => 'assets/images/agencies/$slug.png';

  /// The bundled image to draw, or null when the agency has none.
  String? get imageAsset => assetOverride ?? (hasLogoFile ? logoAsset : null);

  /// Up to two initials, e.g. "Bay Realty" -> "BR".
  static String monogramFor(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'logoFilePath': logoFilePath,
  };

  factory Agency.customFromJson(Map<String, dynamic> json) => Agency.custom(
    slug: json['slug'] as String,
    name: json['name'] as String,
    logoFilePath: json['logoFilePath'] as String?,
  );

  // Compared by value so an agency rebuilt from storage or the API still
  // matches the one selected before, while a restyle (name, logo, colours)
  // does not, so the app re-themes.
  @override
  bool operator ==(Object other) =>
      other is Agency &&
      other.slug == slug &&
      other.name == name &&
      other.logoFilePath == logoFilePath &&
      other.logoUrl == logoUrl &&
      other.primaryColor == primaryColor &&
      other.secondaryColor == secondaryColor &&
      other.onPrimary == onPrimary &&
      other.bannerColor == bannerColor;

  @override
  int get hashCode => Object.hash(
    slug,
    name,
    logoFilePath,
    logoUrl,
    primaryColor,
    secondaryColor,
    onPrimary,
    bannerColor,
  );

  /// The house brand — used when an agent has not picked an agency.
  static const Agency realWorth = Agency(
    slug: 'realworth',
    name: 'RealWorth',
    monogram: 'RW',
    primaryColor: Color(0xFF1B365D),
    secondaryColor: Color(0xFF1E1E1E),
    hasLogoFile: false,
    assetOverride: 'assets/images/logo.jpg',
    bannerColor: Color(0xFFF7F4E5),
  );

  /// The bundled agencies: the offline fallback for `GET /api/agencies`,
  /// which is where new agencies are added now (no app release needed).
  ///
  /// Listed after the house brand and otherwise alphabetical. Only add artwork
  /// you have the right to distribute; these are third-party trademarks.
  static const List<Agency> all = [
    realWorth,
    Agency(
      slug: 'acutts',
      name: 'Acutts Real Estate',
      monogram: 'AC',
      primaryColor: Color(0xFFE4002B),
      secondaryColor: Color(0xFF1E1E1E),
      bannerColor: Color(0xFFE4002B),
    ),
    Agency(
      slug: 'century-21',
      name: 'Century 21',
      monogram: 'C21',
      // The current identity is black with a gold accent, not the older gold.
      primaryColor: Color(0xFF1C1C1C),
      secondaryColor: Color(0xFFB0985E),
      bannerColor: Color(0xFF000000),
    ),
    Agency(
      slug: 'chas-everitt',
      name: 'Chas Everitt',
      monogram: 'CE',
      primaryColor: Color(0xFF245490),
      secondaryColor: Color(0xFFF5A623),
      bannerColor: Colors.white,
    ),
    Agency(
      slug: 'engel-volkers',
      name: 'Engel & Völkers',
      monogram: 'EV',
      primaryColor: Color(0xFFE40000),
      secondaryColor: Color(0xFF242424),
      bannerColor: Colors.white,
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
      bannerColor: Colors.white,
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
      bannerColor: Color(0xFF112347),
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
      bannerColor: Colors.white,
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
      bannerColor: Colors.white,
    ),
    Agency(
      slug: 'tyson',
      name: 'Tyson Properties',
      monogram: 'TP',
      primaryColor: Color(0xFF002E2E),
      secondaryColor: Color(0xFFC9A227),
    ),
  ];

  /// Resolves a stored [slug] back to an agency among [agencies] (by default
  /// the bundled list) and [custom], falling back to the house brand when the
  /// slug is unknown (e.g. removed from the directory).
  static Agency fromSlug(
    String? slug, {
    List<Agency> agencies = all,
    List<Agency> custom = const [],
  }) {
    if (slug == null) return realWorth;
    return [
      ...agencies,
      ...custom,
    ].firstWhere((a) => a.slug == slug, orElse: () => realWorth);
  }

  /// Best-effort match of a free-text agency name typed at registration.
  ///
  /// Returns `null` when nothing matches so callers can keep the typed name
  /// without silently branding the app as the wrong agency.
  static Agency? matchName(
    String? name, {
    List<Agency> agencies = all,
    List<Agency> custom = const [],
  }) {
    final needle = name?.trim().toLowerCase();
    if (needle == null || needle.isEmpty) return null;
    // An exact name wins, so "Bay Realty" added by an agent is not swallowed
    // by a listed agency whose name happens to contain it.
    for (final agency in [...custom, ...agencies]) {
      if (agency.name.toLowerCase() == needle) return agency;
    }
    for (final agency in agencies.where((a) => !a.isCustom)) {
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
