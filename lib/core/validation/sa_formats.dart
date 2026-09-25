import 'package:flutter/services.dart';

/// What a South African ID number says about its holder.
class SaIdInfo {
  final DateTime dateOfBirth;
  final bool isFemale;

  /// True for an SA citizen (digit 11 = 0), false for a permanent resident
  /// (digit 11 = 1).
  final bool isCitizen;

  const SaIdInfo({
    required this.dateOfBirth,
    required this.isFemale,
    required this.isCitizen,
  });
}

/// South African ID numbers: `YYMMDD GGGG CAZ`, 13 digits.
///
/// * `YYMMDD` date of birth
/// * `GGGG` gender: 0000–4999 female, 5000–9999 male
/// * `C` citizenship: 0 SA citizen, 1 permanent resident
/// * `A` legacy digit, usually 8 (sometimes 9)
/// * `Z` Luhn check digit over the first twelve
abstract final class SaIdNumber {
  static const int length = 13;

  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// "8312060001089" → "831206 0001 089"; partial input is grouped as far
  /// as it goes.
  static String format(String input) =>
      _group(digitsOnly(input), const [6, 4, 3]);

  /// Why [input] is not a valid ID number, or null when it is.
  static String? validate(String input) {
    final d = digitsOnly(input);
    if (d.length != length) return 'An ID number has 13 digits';
    if (_dateOfBirth(d) == null) {
      return 'The first 6 digits must be a birth date';
    }
    if (d[10] != '0' && d[10] != '1') return 'Not a valid ID number';
    if (!_luhnValid(d)) return 'Not a valid ID number — check the digits';
    return null;
  }

  /// Birth date, gender and citizenship, or null when [input] is not valid.
  static SaIdInfo? parse(String input) {
    final d = digitsOnly(input);
    if (validate(d) != null) return null;
    return SaIdInfo(
      dateOfBirth: _dateOfBirth(d)!,
      isFemale: int.parse(d.substring(6, 10)) < 5000,
      isCitizen: d[10] == '0',
    );
  }

  /// YYMMDD as a real date. The century is the most recent one that does not
  /// put the birth date in the future.
  static DateTime? _dateOfBirth(String d) {
    final yy = int.parse(d.substring(0, 2));
    final mm = int.parse(d.substring(2, 4));
    final dd = int.parse(d.substring(4, 6));
    final now = DateTime.now();
    var year = 2000 + yy;
    if (DateTime(year, mm, dd).isAfter(now)) year -= 100;
    final date = DateTime(year, mm, dd);
    // DateTime rolls 31 Feb over into March; a mismatch means no such date.
    if (date.month != mm || date.day != dd) return null;
    return date;
  }

  static bool _luhnValid(String d) {
    var total = 0;
    for (var i = 0; i < d.length; i++) {
      var digit = int.parse(d[d.length - 1 - i]);
      if (i.isOdd) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      total += digit;
    }
    return total % 10 == 0;
  }
}

/// South African phone numbers, entered without the +27 country code: nine
/// digits shown as `82 123 4567`, stored as `+27821234567`.
abstract final class SaPhone {
  static const String countryCode = '+27';
  static const int length = 9;

  /// The nine national digits from anything typed or stored: drops spaces,
  /// the +27 / 27 country code and a leading trunk 0 ("082…").
  static String nationalDigits(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('27') && d.length > length) d = d.substring(2);
    if (d.startsWith('0')) d = d.substring(1);
    return d.length > length ? d.substring(0, length) : d;
  }

  /// "821234567" → "82 123 4567".
  static String format(String input) =>
      _group(nationalDigits(input), const [2, 3, 4]);

  /// "+27821234567", or empty when nothing was entered.
  static String toStored(String input) {
    final d = nationalDigits(input);
    return d.isEmpty ? '' : '$countryCode$d';
  }

  /// Why [input] is not a valid SA number, or null when it is. Numbers start
  /// with 1–8 after the country code (mobiles 6, 7, 8; landlines 1–5).
  static String? validate(String input) {
    final d = nationalDigits(input);
    if (d.length != length) return 'Enter the 9 digits after +27';
    if (d[0] == '0' || d[0] == '9') return 'Not a valid SA number';
    return null;
  }
}

/// Keeps only digits and shows them in [groups] separated by spaces, so the
/// agent types digits only and never has to delete a space.
class GroupedDigitsFormatter extends TextInputFormatter {
  final List<int> groups;

  /// Normalises the raw digits before grouping, e.g. dropping a leading 0.
  final String Function(String digits)? normalize;

  GroupedDigitsFormatter(this.groups, {this.normalize});

  int get _maxDigits => groups.fold(0, (a, b) => a + b);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    digits = normalize?.call(digits) ?? digits;
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);

    // Keep the caret after the same number of digits it was after before.
    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    var digitsBeforeCaret = newValue.text
        .substring(0, caret)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    if (digitsBeforeCaret > digits.length) digitsBeforeCaret = digits.length;

    final text = _group(digits, groups);
    var offset = 0;
    var seen = 0;
    while (offset < text.length && seen < digitsBeforeCaret) {
      if (text[offset] != ' ') seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

String _group(String digits, List<int> groups) {
  final parts = <String>[];
  var i = 0;
  for (final size in groups) {
    if (i >= digits.length) break;
    final end = (i + size).clamp(0, digits.length);
    parts.add(digits.substring(i, end));
    i = end;
  }
  return parts.join(' ');
}

/// Email shape check shared by every email field.
bool isValidEmail(String input) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(input.trim());
