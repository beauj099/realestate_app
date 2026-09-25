import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../locale/countries.dart';
import 'sa_formats.dart';

/// Phone numbers for the agent's chosen country: the country code is shown as
/// a fixed prefix, the agent types the national number, and it is stored in
/// international form (`+27821234567`).
///
/// Validation and formatting come from libphonenumber's rules (via
/// `phone_numbers_parser`), so every country's lengths and groupings are
/// right. South Africa keeps its progressive `82 123 4567` grouping as the
/// agent types.
abstract final class CountryPhone {
  static IsoCode? _iso(Country country) {
    for (final iso in IsoCode.values) {
      if (iso.name == country.isoCode) return iso;
    }
    return null;
  }

  /// The national number from anything typed or stored: drops spaces and
  /// punctuation, the +country code, and a leading trunk 0 ("082…").
  static String nationalDigits(String input, Country country) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final international = input.trimLeft().startsWith('+');
    if (international && digits.startsWith(country.dialCode)) {
      digits = digits.substring(country.dialCode.length);
    }
    // Most countries dial a trunk 0 before the national number ("082…",
    // "07911…"); it is not part of the number. Where the 0 *is* part of it
    // (Italy and neighbours), only the version with it is valid — keep that.
    if (digits.startsWith('0')) {
      final iso = _iso(country);
      final stripped = digits.substring(1);
      final zeroBelongs =
          iso != null &&
          PhoneNumber(isoCode: iso, nsn: digits).isValid() &&
          !PhoneNumber(isoCode: iso, nsn: stripped).isValid();
      if (!zeroBelongs) digits = stripped;
    }
    // No national number is longer than 15 digits with its country code.
    final max = 15 - country.dialCode.length;
    return digits.length > max ? digits.substring(0, max) : digits;
  }

  /// The national number as it is usually written, e.g. "82 123 4567".
  static String format(String input, Country country) {
    final nsn = nationalDigits(input, country);
    if (nsn.isEmpty) return '';
    if (country.isoCode == Country.defaultIsoCode) {
      return SaPhone.format(nsn);
    }
    final iso = _iso(country);
    if (iso == null) return nsn;
    return PhoneNumber(isoCode: iso, nsn: nsn).formatNsn();
  }

  /// "+27821234567", or empty when nothing was entered.
  static String toStored(String input, Country country) {
    final nsn = nationalDigits(input, country);
    return nsn.isEmpty ? '' : '${country.dialPrefix}$nsn';
  }

  /// Why [input] is not a valid number for [country], or null when it is.
  static String? validate(String input, Country country) {
    final nsn = nationalDigits(input, country);
    if (nsn.isEmpty) return 'Enter the number after ${country.dialPrefix}';
    if (country.isoCode == Country.defaultIsoCode) {
      return SaPhone.validate(nsn);
    }
    final iso = _iso(country);
    if (iso == null) return null;
    // Length, not the number-range patterns: the bundled range data lags
    // behind real allocations (it rejects live UK 7911… mobiles), and
    // blocking a genuine number is worse than accepting an odd one.
    return PhoneNumber(isoCode: iso, nsn: nsn).isValidLength()
        ? null
        : 'Not a valid ${country.name} number';
  }

  /// Formats as the agent types: digits only, grouped for [country].
  static TextInputFormatter inputFormatter(Country country) {
    if (country.isoCode == Country.defaultIsoCode) {
      return GroupedDigitsFormatter(
        const [2, 3, 4],
        normalize: SaPhone.nationalDigits,
      );
    }
    return _CountryPhoneFormatter(country);
  }
}

class _CountryPhoneFormatter extends TextInputFormatter {
  final Country country;

  _CountryPhoneFormatter(this.country);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = CountryPhone.format(newValue.text, country);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
