import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/data/property_report_repository.dart';
import 'package:realworth/features/property_report/data/report_cache.dart';

void main() {
  final reportJson =
      jsonDecode(
            File('test/fixtures/property_report_53927.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('a saved report reads back as it was', () {
    final saved = ReportSnapshot(
      key: 'k',
      generatedAt: DateTime(2026, 9, 30, 14, 5),
      candidate: const PropertyCandidate(
        municipality: 'coct',
        erf: '53927',
        suburb: 'CLAREMONT',
        township: 'CLAREMONT',
      ).toJson(),
      report: reportJson,
      sitePlanSvg: '<svg/>',
      blockMapSvg: '<svg id="block"/>',
      market: const [],
    );

    // Through JSON text, as on disk.
    final back = ReportSnapshot.fromJson(
      jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
    )!;

    expect(back.generatedAt, saved.generatedAt);
    expect(back.blockMapSvg, '<svg id="block"/>');
    expect(PropertyCandidate.fromJson(back.candidate).erf, '53927');
    final report = PropertyReport.fromJson(back.report);
    expect(report.erf, '53927');
    expect(report.indicativeValue!.low, isNotNull);
  });

  test('an unknown file version is ignored, not misread', () {
    expect(ReportSnapshot.fromJson({'version': 99}), isNull);
  });

  test('the key changes with the address, erf or pin, nothing else', () {
    const base = ReportQuery(
      address: '10 Bosman Street, Strand',
      erf: '4429',
      lat: -34.11,
      lng: 18.82,
    );
    final key = ReportSnapshot.keyFor(base);
    expect(
      ReportSnapshot.keyFor(
        const ReportQuery(
          address: '  10 bosman street, strand ',
          erf: '4429',
          lat: -34.11,
          lng: 18.82,
          suburb: 'STRAND',
        ),
      ),
      key,
    );
    expect(
      ReportSnapshot.keyFor(
        const ReportQuery(address: '10 Bosman Street, Strand', erf: '4430'),
      ),
      isNot(key),
    );
    expect(
      ReportSnapshot.keyFor(
        const ReportQuery(
          address: '10 Bosman Street, Strand',
          erf: '4429',
          lat: -34.12,
          lng: 18.82,
        ),
      ),
      isNot(key),
    );
  });
}
