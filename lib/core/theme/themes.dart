import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'agency.dart';

/// Represents the styling configuration for a real estate brand.
class RealEstateTheme {
  final String brandName;

  /// The white-label agency this theme was built from.
  final Agency agency;
  final Color primaryColor; // e.g., Navy (#1B365D) for RealWorth
  final Color secondaryColor; // e.g., Slate/Stone
  final Color backgroundColor; // Light gray/cream editorial background
  final Color cardBackgroundColor; // Clean white cards
  final Color textPrimary; // High contrast charcoal/black
  final Color textSecondary; // Subtle zinc/grey
  final Color textLabel; // Warm brown for labels
  
  final Color completeColor; // Semantic green for completed rooms
  final Color pendingColor; // Semantic orange for pending items
  
  final Color borderLight;
  final Color borderSelected;

  // Semantic tokens (default to light-theme values; dark factory overrides)
  final Color onPrimary; // Text/icons rendered on top of primaryColor
  final Color error; // Error text, destructive actions, error snackbars
  final Color errorBackground; // Soft error badge/background fill
  final Color imagePlaceholder; // Empty/broken image placeholder fill
  final Color mutedIcon; // Low-emphasis icons (e.g. placeholder glyphs)
  final Color shadow; // Base color for shadows/scrims (used with alpha)

  RealEstateTheme({
    required this.brandName,
    this.agency = Agency.realWorth,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.cardBackgroundColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLabel,
    required this.completeColor,
    required this.pendingColor,
    required this.borderLight,
    required this.borderSelected,
    this.onPrimary = Colors.white,
    this.error = const Color(0xFFDC2626),
    this.errorBackground = const Color(0xFFFEE2E2),
    this.imagePlaceholder = const Color(0xFFE5E7EB),
    this.mutedIcon = const Color(0xFF9CA3AF),
    this.shadow = Colors.black,
  });

  /// Factory for the default RealWorth theme
  factory RealEstateTheme.crimson() {
    return RealEstateTheme(
      brandName: 'RealWorth',
      primaryColor: const Color(0xFF1B365D),
      secondaryColor: const Color(0xFF1E1E1E),
      backgroundColor: const Color(0xFFFAF9F6), // Sophisticated editorial off-white
      cardBackgroundColor: Colors.white,
      textPrimary: const Color(0xFF111111),
      textSecondary: const Color(0xFF71717A),
      textLabel: const Color(0xFF5C4033), // Elegant brown label style
      completeColor: const Color(0xFF0F9D58), // Emerald green
      pendingColor: const Color(0xFFD97706), // Amber/orange
      borderLight: const Color(0xFFE4E4E7),
      borderSelected: const Color(0xFF1B365D),
    );
  }

  /// Factory for a modern "Editorial Slate" brand
  factory RealEstateTheme.slate() {
    return RealEstateTheme(
      brandName: 'Editorial Slate',
      primaryColor: const Color(0xFF2D3748), // Cool slate
      secondaryColor: const Color(0xFF1A202C),
      backgroundColor: const Color(0xFFF7FAFC),
      cardBackgroundColor: Colors.white,
      textPrimary: const Color(0xFF1A202C),
      textSecondary: const Color(0xFF718096),
      textLabel: const Color(0xFF4A5568),
      completeColor: const Color(0xFF319795),
      pendingColor: const Color(0xFFDD6B20),
      borderLight: const Color(0xFFE2E8F0),
      borderSelected: const Color(0xFF2D3748),
    );
  }

  /// Dark variant of the default RealWorth theme
  factory RealEstateTheme.crimsonDark() {
    return RealEstateTheme(
      brandName: 'RealWorth Dark',
      primaryColor: const Color(0xFF2A4B6E),
      secondaryColor: const Color(0xFF3A3A3A),
      backgroundColor: const Color(0xFF121212),
      cardBackgroundColor: const Color(0xFF1E1E1E),
      textPrimary: const Color(0xFFE4E4E7),
      textSecondary: const Color(0xFFA1A1AA),
      textLabel: const Color(0xFFD4B5A0),
      completeColor: const Color(0xFF4ADE80),
      pendingColor: const Color(0xFFFBBF24),
      borderLight: const Color(0xFF333333),
      borderSelected: const Color(0xFF2A4B6E),
      error: const Color(0xFFF87171),
      errorBackground: const Color(0xFF4C1D1D),
      imagePlaceholder: const Color(0xFF2A2A2A),
      mutedIcon: const Color(0xFF6B7280),
    );
  }

  /// Light theme carrying [agency]'s palette over the house layout.
  ///
  /// Only the brand-owned colours change; the editorial background, semantic
  /// status colours and typography stay constant so every agency's build looks
  /// like the same product.
  factory RealEstateTheme.fromAgency(Agency agency) {
    final base = RealEstateTheme.crimson();
    return RealEstateTheme(
      brandName: agency.name,
      agency: agency,
      primaryColor: agency.primaryColor,
      secondaryColor: agency.secondaryColor,
      backgroundColor: base.backgroundColor,
      cardBackgroundColor: base.cardBackgroundColor,
      textPrimary: base.textPrimary,
      textSecondary: base.textSecondary,
      textLabel: base.textLabel,
      completeColor: base.completeColor,
      pendingColor: base.pendingColor,
      borderLight: base.borderLight,
      borderSelected: agency.primaryColor,
      onPrimary: agency.onPrimary,
    );
  }

  /// Dark counterpart of [RealEstateTheme.fromAgency].
  ///
  /// The brand primary is lightened so it keeps enough contrast against the
  /// dark surface; very light brands are darkened instead.
  factory RealEstateTheme.fromAgencyDark(Agency agency) {
    final base = RealEstateTheme.crimsonDark();
    final hsl = HSLColor.fromColor(agency.primaryColor);
    final adjusted = hsl.lightness > 0.6
        ? hsl.withLightness(0.45)
        : hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0));
    final primary = adjusted.toColor();
    return RealEstateTheme(
      brandName: '${agency.name} Dark',
      agency: agency,
      primaryColor: primary,
      secondaryColor: base.secondaryColor,
      backgroundColor: base.backgroundColor,
      cardBackgroundColor: base.cardBackgroundColor,
      textPrimary: base.textPrimary,
      textSecondary: base.textSecondary,
      textLabel: base.textLabel,
      completeColor: base.completeColor,
      pendingColor: base.pendingColor,
      borderLight: base.borderLight,
      borderSelected: primary,
      onPrimary: Colors.white,
      error: base.error,
      errorBackground: base.errorBackground,
      imagePlaceholder: base.imagePlaceholder,
      mutedIcon: base.mutedIcon,
    );
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: onPrimary,
        secondary: secondaryColor,
        surface: cardBackgroundColor,
        error: error,
      ),
      textTheme: _textTheme(),
    );
  }

  ThemeData toDarkThemeData() {
    final dark = RealEstateTheme.fromAgencyDark(agency);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dark.backgroundColor,
      primaryColor: dark.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: dark.primaryColor,
        onPrimary: dark.onPrimary,
        secondary: dark.secondaryColor,
        surface: dark.cardBackgroundColor,
        error: dark.error,
      ),
      textTheme: dark._textTheme(),
    );
  }

  TextTheme _textTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: textLabel,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    );
  }
}
