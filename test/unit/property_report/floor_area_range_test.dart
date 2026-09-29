import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';

/// 10 Bosman Street, Strand: the seven sales the City's records give (indexed
/// to today) and the City's dwelling extent of 477 m².
Map<String, dynamic> _sale(double indexed, double floor) => {
  'address': 'x',
  'erfExtentM2': 600,
  'dwellingExtentM2': floor,
  'saleDate': '2025-01-01',
  'salePriceZar': indexed,
  'indexedPriceZar': indexed,
  'included': true,
};

PropertyReport _report() => PropertyReport.fromJson({
  'erf': '4429',
  'dwellingExtentM2': 477,
  'indicativeValue': {'low': 3660000, 'mid': 4040000, 'high': 4370000},
  'comparables': [
    _sale(3266960, 460),
    _sale(2796265, 265),
    _sale(3988169, 364),
    _sale(3043800, 297),
    _sale(3101604, 306),
    _sale(4191507, 349),
    _sale(2170627, 256),
  ],
});

void main() {
  test('carries the sales to the floor area on the listing', () {
    final r = _report().forListingFloorArea(620);
    expect(r.sizedFromListingM2, 620);
    expect(r.bestRange!.low, 4280000);
    expect(r.bestRange!.mid, 4730000);
    expect(r.bestRange!.high, 5110000);
  });

  test('keeps the City range when the sizes agree or none is given', () {
    expect(_report().forListingFloorArea(480).bestRange!.mid, 4040000);
    expect(_report().forListingFloorArea(null).sizedFromListingM2, isNull);
  });
}
