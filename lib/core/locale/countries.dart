part 'country_data.dart';

/// A country with its dialling code and currency.
///
/// The list itself ([Country.all]) is generated from CLDR and libphonenumber
/// into `country_data.dart`, so names, codes and symbols are authoritative
/// rather than typed from memory.
class Country {
  /// ISO 3166-1 alpha-2, e.g. `ZA`.
  final String isoCode;
  final String name;

  /// Country calling code without the plus, e.g. `27`.
  final String dialCode;

  /// ISO 4217, e.g. `ZAR`.
  final String currencyCode;

  /// The symbol used at home, e.g. `R`, `£`, `€`.
  final String currencySymbol;
  final String currencyName;

  const Country(
    this.isoCode,
    this.name,
    this.dialCode,
    this.currencyCode,
    this.currencySymbol,
    this.currencyName,
  );

  /// The flag emoji, built from the ISO code's regional-indicator letters.
  String get flag => String.fromCharCodes(
    isoCode.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
  );

  /// "+27"
  String get dialPrefix => '+$dialCode';

  static const String defaultIsoCode = 'ZA';

  static List<Country> get all => _countries;

  static Country get southAfrica => byIso(defaultIsoCode);

  /// The country for [isoCode], falling back to South Africa.
  static Country byIso(String? isoCode) {
    final code = isoCode?.toUpperCase();
    return _countries.firstWhere(
      (c) => c.isoCode == code,
      orElse: () => _countries.firstWhere((c) => c.isoCode == defaultIsoCode),
    );
  }

  /// South Africa first, then every other country alphabetically.
  static List<Country> get ordered {
    final rest =
        _countries.where((c) => c.isoCode != defaultIsoCode).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return [southAfrica, ...rest];
  }

  @override
  bool operator ==(Object other) =>
      other is Country && other.isoCode == isoCode;

  @override
  int get hashCode => isoCode.hashCode;
}
