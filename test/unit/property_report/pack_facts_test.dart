import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/office_details.dart';
import 'package:realworth/features/property_overview/data/models/property_state.dart';
import 'package:realworth/features/property_report/report/pack_listing.dart';

void main() {
  test('zoning is written out for owners', () {
    expect(
      readableZoning('R1', 'Residential 1 : Conventional Housing'),
      'Residential 1 (Conventional Housing)',
    );
    expect(
      readableZoning('GR2', 'General Residential 2'),
      'General Residential 2',
    );
    expect(readableZoning('R1', null), 'R1');
    expect(readableZoning(null, ''), isNull);
  });

  test('features without a number are listed by name', () {
    const facts = PackFacts(pool: true, fibre: true, backupPower: true);
    expect(facts.extras.map((e) => e.$2), [
      'Pool',
      'Fibre internet',
      'Backup power',
    ]);
  });

  test('office logos and wording fall back to the agency, one by one', () {
    const agency = OfficeDetails(
      slogan: 'we have what it takes',
      logos: OfficeLogos(mark: 'agency-mark', wide: 'agency-wide'),
    );
    const office = OfficeDetails(logos: OfficeLogos(wide: 'office-wide'));
    final merged = office.orDefaults(agency);
    expect(merged.slogan, 'we have what it takes');
    expect(merged.logos.mark, 'agency-mark');
    expect(merged.logos.wide, 'office-wide');
    expect(merged.logos.wideOnBrand, isNull);
  });

  test('ticked outdoor and lifestyle features reach the cover', () {
    final facts = packFacts(
      PropertyState(
        outdoorFeatures: [
          'Garden',
          'Pet Friendly',
          'Fibre Internet',
          'Swimming Pool',
          'Flatlet / Garden Cottage',
        ],
      ),
      const {},
    );
    expect(facts.extras.map((e) => e.$2), [
      'Pool',
      'Flatlet',
      'Garden',
      'Fibre internet',
      'Pet friendly',
    ]);
  });
}
