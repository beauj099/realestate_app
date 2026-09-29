import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/office_details.dart';
import 'package:realworth/features/property_report/data/models/area_details.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/report/costs_calculator.dart';
import 'package:realworth/features/property_report/report/report_pack_pdf.dart';
import 'package:realworth/features/property_report/report/valuation_report_pdf.dart';

PropertyReport _fixture() => PropertyReport.fromJson(
  jsonDecode(
        File('test/fixtures/property_report_53927.json').readAsStringSync(),
      )
      as Map<String, dynamic>,
);

ReportPackPdf _pack({AreaDetails? area, ForSale? forSale}) => ReportPackPdf(
  report: _fixture(),
  sitePlanSvg: File('test/fixtures/site_plan_53927.svg').readAsStringSync(),
  images: const {},
  agent: const PackAgent(
    name: 'Jane Agent',
    jobTitle: 'Property Practitioner',
    agencyName: 'Keller Williams',
    ppraNumber: '1234567',
    office: OfficeDetails(
      name: 'KW Test',
      footer: 'Each office is independently owned',
    ),
  ),
  listing: const PackListing(
    preparedFor: 'Mr & Mrs Smith',
    greeting: 'John & Mary',
  ),
  valuation: const PackValuation(
    low: 7000000,
    high: 7500000,
    listingPrice: 7900000,
  ),
  costs: const CostsSummary(
    valuationPrice: 7500000,
    listingPrice: 7900000,
    commissionEarlyPercent: 5,
    commissionLatePercent: 6,
    earlyMonths: 2,
    commissionIncludesVat: false,
    interestRatePercent: 10.75,
    bondTermYears: 20,
    depositPercent: 0,
  ),
  area: area,
  forSale: forSale,
  pictures: const PackImages(),
  brandColor: const Color(0xFFB41F25),
  date: DateTime(2026, 9, 27),
);

void main() {
  // The PDFs load their font from the asset bundle.
  TestWidgetsFlutterBinding.ensureInitialized();
  test('builds the pack, leaving out sections without data', () async {
    final bare = _pack();
    expect(bare.sections, isNot(contains('Area details')));
    expect(bare.sections, isNot(contains('Homes on the market like yours')));
    final bytes = await bare.build();
    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');

    final full = _pack(
      area: const AreaDetails(
        crime: CrimeStats(
          precinct: 'Claremont',
          period: 'Oct 2024 – Sept 2025',
          previousPeriod: 'Oct 2023 – Sept 2024',
          crimes: [CrimeCount('Residential burglary', 100, 120)],
          total: 900,
          previousTotal: 1000,
          source: 'SAPS',
        ),
      ),
      forSale: const ForSale(
        source: 'Property24',
        attribution: 'Listings from Property24.com.',
        listings: [
          ForSaleListing(
            listingNumber: '1',
            url: 'https://www.property24.com/x/1',
            title: '4 Bedroom House',
            priceZar: 7800000,
          ),
        ],
      ),
    );
    expect(
      full.sections,
      containsAll(['Area details', 'Homes on the market like yours']),
    );
    expect((await full.build()).length, greaterThan(bytes.length));
  });

  test('typographic punctuation becomes plain for the PDF fonts', () {
    expect(
      pdfText('Oct 2024 – Sept 2025 … “quoted” it’s'),
      'Oct 2024 - Sept 2025 ... "quoted" it\'s',
    );
  });
}
