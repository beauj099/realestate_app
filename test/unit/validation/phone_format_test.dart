import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/locale/countries.dart';
import 'package:realworth/core/validation/phone_format.dart';

void main() {
  final za = Country.southAfrica;
  final gb = Country.byIso('GB');
  final us = Country.byIso('US');

  test('South Africa: local, +27 and spaced forms agree', () {
    for (final input in ['0845003483', '+27845003483', '84 500 3483']) {
      expect(CountryPhone.nationalDigits(input, za), '845003483');
      expect(CountryPhone.validate(input, za), isNull);
    }
    expect(CountryPhone.format('0845003483', za), '84 500 3483');
    expect(CountryPhone.toStored('084 500 3483', za), '+27845003483');
  });

  test('UK mobile: trunk 0 dropped, formatted, stored with +44', () {
    expect(CountryPhone.nationalDigits('07911 123456', gb), '7911123456');
    expect(CountryPhone.validate('07911 123456', gb), isNull);
    expect(CountryPhone.toStored('07911 123456', gb), '+447911123456');
    expect(CountryPhone.format('7911123456', gb), '7911 123456');
  });

  test('US number validates against US rules', () {
    expect(CountryPhone.validate('(201) 555-0123', us), isNull);
    expect(CountryPhone.validate('555', us), isNotNull);
    expect(CountryPhone.toStored('2015550123', us), '+12015550123');
  });

  test('countries: South Africa first, flags, currencies', () {
    final ordered = Country.ordered;
    expect(ordered.first.isoCode, 'ZA');
    expect(ordered[1].name.compareTo(ordered[2].name), lessThan(0));
    expect(za.flag, '🇿🇦');
    expect(za.currencySymbol, 'R');
    expect(za.dialPrefix, '+27');
    expect(Country.byIso('xx'), za);
    expect(Country.all.length, greaterThan(200));
  });
}
