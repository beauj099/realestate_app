import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/report/valuation_report_pdf.dart';

// Fixture: a live report for 17 Pine Road, Claremont (erf 53927), trimmed to a
// few comparables. Public municipal data, recorded 2026-09-26.
PropertyReport _fixture({List<Map<String, dynamic>>? imagery}) {
  final json =
      jsonDecode(
            File('test/fixtures/property_report_53927.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  if (imagery != null) json['imagery'] = imagery;
  return PropertyReport.fromJson(json);
}

void main() {
  group('PropertyReport.fromJson', () {
    test('reads the live report', () {
      final r = _fixture();
      expect(r.erf, '53927');
      expect(r.valuationRef, 'CCT010812600000');
      expect(r.displayAddress, '17 Pine Road, Claremont');
      expect(r.extentM2, 1085);
      expect(r.dwellingExtentM2, 300);
      expect(r.municipalValueZar, 7100000);
      expect(r.municipalValueAsAt, DateTime(2025, 7, 1));
      expect(r.zoningCode, 'GR2');
      expect(r.buildings.first.roofM2, closeTo(258, 8));
      expect(r.comparableSummary!.raw, greaterThan(2000));
      expect(r.indicativeValue!.low, lessThan(r.indicativeValue!.high!));
      expect(r.comparables, isNotEmpty);
      expect(r.provenance.map((p) => p.field), contains('comparables'));
    });

    test('only satellite imagery is printable', () {
      final r = _fixture(
        imagery: [
          {
            'kind': 'satellite',
            'url': '/sat',
            'attribution': 'Imagery © Google',
            'allowedInPrint': true,
          },
          {
            'kind': 'streetview',
            'url': '/sv',
            'attribution': '© Google Street View',
            'allowedInPrint': false,
          },
        ],
      );
      expect(r.printableImagery.map((i) => i.kind), ['satellite']);
      expect(r.screenOnlyImagery.map((i) => i.kind), ['streetview']);
    });
  });

  test('Rand is grouped with non-breaking spaces', () {
    expect(rand(7100000), 'R 7 100 000');
    expect(groupDigits(1085), '1 085');
    expect(groupDigits(59), '59');
  });

  test('titleCase', () {
    expect(titleCase('17 PINE ROAD CLAREMONT'), '17 Pine Road Claremont');
    expect(titleCase(''), '');
  });

  group('ValuationReportPdf', () {
    Future<Uint8List> build({Map<String, Uint8List> images = const {}}) {
      final report = _fixture(
        imagery: [
          {
            'kind': 'streetview',
            'url': '/sv',
            'attribution': '© Google Street View',
            'allowedInPrint': false,
          },
        ],
      );
      return ValuationReportPdf(
        report: report,
        sitePlanSvg: File(
          'test/fixtures/site_plan_53927.svg',
        ).readAsStringSync(),
        images: images,
        author: const ReportAuthor(
          name: 'Jane Agent',
          agencyName: 'Pam Golding Properties',
          mobile: '+27 82 123 4567',
        ),
        brandColor: const Color(0xFF014423),
        date: DateTime(2026, 9, 26),
      ).build();
    }

    test('produces a PDF', () async {
      final bytes = await build();
      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(5000));
      // Kept for a visual check: build/valuation_report_sample.pdf
      File('build/valuation_report_sample.pdf')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    });

    test('never prints Street View, even when its bytes are loaded', () async {
      final withStreetView = await build(
        images: {
          '/sv': File(
            'test/fixtures/street_view_placeholder.png',
          ).readAsBytesSync(),
        },
      );
      final without = await build();
      // Same document either way: the Street View image is not embedded.
      expect(withStreetView.length, without.length);
    });
  });
}
