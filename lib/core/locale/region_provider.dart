import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'countries.dart';

/// The agent's country (phone numbers, ID format) and currency (money
/// fields). Chosen separately in Settings; registration sets both.
class RegionSettings {
  final Country country;

  /// The country whose currency is used — any country can be picked, so an
  /// agent in Namibia can still work in Rand.
  final Country currencyCountry;

  const RegionSettings({required this.country, required this.currencyCountry});

  String get currencySymbol => currencyCountry.currencySymbol;

  bool get isSouthAfrica => country.isoCode == Country.defaultIsoCode;
}

const String _countryKey = 'regionCountry';
const String _currencyKey = 'regionCurrencyCountry';

/// Holds [RegionSettings], saved on the device. Defaults to South Africa for
/// both until the agent chooses otherwise.
class RegionNotifier extends Notifier<RegionSettings> {
  @override
  RegionSettings build() {
    _load();
    final za = Country.southAfrica;
    return RegionSettings(country: za, currencyCountry: za);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString(_countryKey);
    final currency = prefs.getString(_currencyKey);
    if (country == null && currency == null) return;
    state = RegionSettings(
      country: Country.byIso(country),
      currencyCountry: Country.byIso(currency ?? country),
    );
  }

  Future<void> setCountry(Country country) async {
    state = RegionSettings(
      country: country,
      currencyCountry: state.currencyCountry,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, country.isoCode);
  }

  Future<void> setCurrency(Country currencyCountry) async {
    state = RegionSettings(
      country: state.country,
      currencyCountry: currencyCountry,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCountry.isoCode);
  }

  /// Sets country and currency together, as registration does.
  Future<void> setBoth(Country country) async {
    state = RegionSettings(country: country, currencyCountry: country);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, country.isoCode);
    await prefs.setString(_currencyKey, country.isoCode);
  }
}

final regionProvider = NotifierProvider<RegionNotifier, RegionSettings>(
  RegionNotifier.new,
);
