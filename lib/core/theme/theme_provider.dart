import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agency.dart';
import 'themes.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.light;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? false;
    if (isDark) {
      state = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', mode == ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Preference key holding the selected white-label agency slug.
const String _agencyPrefsKey = 'agencySlug';

/// Holds the agency whose branding the app is currently wearing.
class AgencyNotifier extends Notifier<Agency> {
  @override
  Agency build() {
    _loadFromPrefs();
    return Agency.realWorth;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final slug = prefs.getString(_agencyPrefsKey);
    if (slug != null) state = Agency.fromSlug(slug);
  }

  Future<void> setAgency(Agency agency) async {
    state = agency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_agencyPrefsKey, agency.slug);
  }
}

final agencyProvider = NotifierProvider<AgencyNotifier, Agency>(
  AgencyNotifier.new,
);

final themeConfigProvider = Provider<RealEstateTheme>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final agency = ref.watch(agencyProvider);
  return themeMode == ThemeMode.dark
      ? RealEstateTheme.fromAgencyDark(agency)
      : RealEstateTheme.fromAgency(agency);
});
