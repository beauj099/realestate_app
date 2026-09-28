import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_report/data/models/agent_sales.dart';
import 'package:realworth/features/property_report/data/models/property_report.dart';
import 'package:realworth/features/property_report/report/valuation_report_pdf.dart';

Map<String, dynamic> _sale(
  String address,
  num price, {
  String evidence = 'OwnTransaction',
  String verification = 'Unverified',
  bool isMine = false,
}) => {
  'id': '1be31ed9-d5b9-f111-b533-bc24116166eb',
  'address': address,
  'suburb': 'CLAREMONT',
  'floorM2': 250.0,
  'erfM2': 900.0,
  'saleDate': '2026-06-01',
  'salePriceZar': price,
  'pricePerFloorM2': price / 250,
  'evidenceLevel': evidence,
  'evidence': 'Agent\'s own sale',
  'verification': verification,
  'corroborationCount': 1,
  'weight': 0.81,
  'isMine': isMine,
};

/// The Claremont fixture, optionally without its municipal range (as in an
/// area with no sales data) and with agent-reported sales.
PropertyReport _report({
  bool municipalRange = true,
  Map<String, dynamic>? agent,
}) {
  final json =
      jsonDecode(
            File('test/fixtures/property_report_53927.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  if (!municipalRange) json['indicativeValue'] = null;
  json['agentComparables'] = agent;
  return PropertyReport.fromJson(json);
}

final _agent = {
  'sales': [
    _sale('12 Oak Avenue', 7200000),
    _sale('3 Elm Road', 9900000, evidence: 'Hearsay', verification: 'Disputed'),
  ],
  'evidenceStatement': '2 sales in Claremont reported by agents.',
  'weightedMedianPerFloorM2': 28800.0,
  'indicativeValue': {'low': 7800000, 'mid': 8600000, 'high': 9400000},
  'indicativeBasis': 'floor',
};

void main() {
  test('reads agent-reported sales from the report', () {
    final r = _report(agent: _agent);
    final agent = r.agentSales!;
    expect(agent.sales, hasLength(2));
    expect(agent.sales.first.evidence, EvidenceLevel.ownTransaction);
    expect(agent.sales.last.isDisputed, isTrue);
    expect(agent.indicativeBasis, 'floor');
    expect(_report().agentSales, isNull);
  });

  test('the municipal range wins; agent sales fill in only without one', () {
    final withCity = _report(agent: _agent);
    expect(withCity.rangeFromAgentSales, isFalse);
    expect(withCity.bestRange, same(withCity.indicativeValue));

    final agentOnly = _report(municipalRange: false, agent: _agent);
    expect(agentOnly.rangeFromAgentSales, isTrue);
    expect(agentOnly.bestRange!.mid, 8600000);
  });

  test('agents can only claim evidence they can have', () {
    expect(
      EvidenceLevel.capturable,
      isNot(contains(EvidenceLevel.deedsVerified)),
    );
    expect(EvidenceLevel.fromWire('SignedOffer'), EvidenceLevel.signedOffer);
    expect(EvidenceLevel.fromWire('nonsense'), EvidenceLevel.hearsay);
  });

  test('a new sale is sent with a plain date and without empty fields', () {
    final json = NewAgentSale(
      municipality: 'coct',
      suburb: 'CLAREMONT',
      address: ' 12 Oak Avenue ',
      saleDate: DateTime(2026, 3, 7),
      salePriceZar: 7200000,
      evidence: EvidenceLevel.signedOffer,
      floorM2: 250,
      notes: '  ',
    ).toJson();
    expect(json['saleDate'], '2026-03-07');
    expect(json['address'], '12 Oak Avenue');
    expect(json['evidenceLevel'], 'SignedOffer');
    expect(json['floorM2'], 250);
    expect(json.containsKey('erfM2'), isFalse);
    expect(json.containsKey('condition'), isFalse);
    expect(json.containsKey('notes'), isFalse);
  });

  test('the PDF prints agent sales and a range from them', () async {
    final bytes = await ValuationReportPdf(
      report: _report(municipalRange: false, agent: _agent),
      sitePlanSvg: null,
      images: const {},
      author: const ReportAuthor(name: 'Jane Agent'),
      brandColor: const Color(0xFF014423),
      date: DateTime(2026, 9, 26),
    ).build();
    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    // Kept for a visual check: build/valuation_report_agent_sales.pdf
    File('build/valuation_report_agent_sales.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });
}
