import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/property_report.dart';

/// Who prepared the report, printed on the cover.
class ReportAuthor {
  final String name;
  final String agencyName;
  final String email;
  final String mobile;
  final String licenceNumber;

  const ReportAuthor({
    this.name = '',
    this.agencyName = '',
    this.email = '',
    this.mobile = '',
    this.licenceNumber = '',
  });
}

/// Builds the valuation report PDF from a [PropertyReport].
///
/// Licence rules, enforced here rather than trusted to the caller:
///   * Only [PropertyReport.printableImagery] is drawn (satellite). Street View
///     is never printed.
///   * Each image keeps its attribution directly beneath it, and is scaled to
///     fit (never cropped).
///   * The site plan is our own drawing from open municipal data, so it needs
///     no attribution box.
///   * No personal information: comparables show addresses and prices only.
class ValuationReportPdf {
  final PropertyReport report;
  final String? sitePlanSvg;
  final Map<String, Uint8List> images;
  final ReportAuthor author;
  final Color brandColor;
  final DateTime date;

  ValuationReportPdf({
    required this.report,
    required this.sitePlanSvg,
    required this.images,
    required this.author,
    required this.brandColor,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  static final _day = DateFormat('d MMMM yyyy');
  static final _month = DateFormat('MMM yyyy');

  static String _money(num? v) => v == null ? '-' : rand(v);
  static String _m2(num? v) => v == null ? '-' : '${groupDigits(v)} m²';
  static String _count(int v) => groupDigits(v);

  PdfColor get _brand => PdfColor.fromInt(brandColor.toARGB32());
  static const _ink = PdfColor.fromInt(0xFF1E1E1E);
  static const _muted = PdfColor.fromInt(0xFF6B6F76);
  static const _rule = PdfColor.fromInt(0xFFDDDFE3);

  String get fileName =>
      'Valuation report - ${report.displayAddress.replaceAll(',', '')}.pdf';

  Future<Uint8List> build() async {
    final doc = pw.Document(
      title: 'Valuation report - ${report.displayAddress}',
      author: author.name.isEmpty ? null : author.name,
      creator: 'RealWorth',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 40),
        header: _header,
        footer: _footer,
        build: (context) => [
          _title(),
          pw.SizedBox(height: 14),
          _rangeBox(),
          if (report.coverageNote != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                report.coverageNote!,
                style: pw.TextStyle(
                  color: _muted,
                  fontSize: 8.5,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          pw.SizedBox(height: 18),
          ..._sitePlan(),
          ..._printableImagery(),
          _section('Property', [
            ('Address', report.displayAddress),
            ('Erf', '${report.erf} ${titleCase(report.township)}'),
            if (report.valuationRef != null)
              ('Valuation reference', report.valuationRef!),
            ('Erf extent', _m2(report.extentM2)),
            if (report.zoningDescription != null)
              (
                'Zoning',
                [
                  report.zoningCode,
                  report.zoningDescription,
                ].whereType<String>().join(' - '),
              ),
            if (report.ward != null) ('Ward', report.ward!),
            if (report.legalStatus != null)
              ('Legal status', report.legalStatus!),
          ]),
          _section('Improvements', [
            if (report.dwellingExtentM2 != null)
              ('Dwelling extent (City record)', _m2(report.dwellingExtentM2)),
            if (report.totalRoofM2 != null)
              ('Roof area, all buildings', _m2(report.totalRoofM2)),
            for (final (i, b) in report.buildings.indexed)
              (
                i == 0 ? 'Main building' : 'Building ${i + 1}',
                [
                  '${_m2(b.roofM2)} roof',
                  if (b.heightM != null)
                    '${b.heightM!.toStringAsFixed(1)} m high',
                  if (b.estimatedStoreys != null)
                    'approx. ${b.estimatedStoreys} storey${b.estimatedStoreys == 1 ? '' : 's'}',
                ].join(', '),
              ),
          ], note: _footprintNote()),
          if (report.approvedWork.isNotEmpty) _approvedWork(),
          _section('Municipal valuation', [
            ('Market value', _money(report.municipalValueZar)),
            if (report.municipalValueAsAt != null)
              ('Valued as at', _day.format(report.municipalValueAsAt!)),
            if (report.ratingCategory != null)
              ('Rating category', titleCase(report.ratingCategory!)),
            if (report.rollVersion != null) ('Roll', report.rollVersion!),
          ]),
          if (report.suburbStats case final s?)
            _section('Suburb: ${titleCase(s.name)}', [
              ('Residential properties', _count(s.residentialCount)),
              ('Median value, GV2022', _money(s.gv2022)),
              ('Median value, GV2025', _money(s.gv2025)),
              (
                'Change',
                '${s.growthPercent >= 0 ? '+' : ''}${s.growthPercent.toStringAsFixed(1)}% '
                    '(${s.annualGrowthPercent.toStringAsFixed(1)}% a year)',
              ),
              (
                'Median land / building',
                '${_m2(s.medianLandM2)} / ${_m2(s.medianBuildingM2)}',
              ),
            ]),
          ..._comparables(),
          _method(),
          _disclaimer(),
          _sources(),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _header(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 8),
    margin: const pw.EdgeInsets.only(bottom: 14),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 2)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          author.agencyName.isEmpty
              ? 'Property valuation report'
              : author.agencyName,
          style: pw.TextStyle(
            color: _brand,
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
          ),
        ),
        pw.Text(
          _day.format(date),
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
      ],
    ),
  );

  pw.Widget _footer(pw.Context context) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'Indicative only - not a certified valuation',
        style: const pw.TextStyle(color: _muted, fontSize: 8),
      ),
      pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: _muted, fontSize: 8),
      ),
    ],
  );

  pw.Widget _title() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'PROPERTY VALUATION REPORT',
        style: pw.TextStyle(
          color: _brand,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        report.displayAddress,
        style: pw.TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        [
          'Erf ${report.erf} ${titleCase(report.township)}',
          if (report.valuationRef != null)
            'Valuation ref ${report.valuationRef}',
        ].join('   ·   '),
        style: const pw.TextStyle(color: _muted, fontSize: 10),
      ),
      if (author.name.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Text(
          [
            'Prepared by ${author.name}',
            if (author.licenceNumber.isNotEmpty) 'FFC ${author.licenceNumber}',
            if (author.mobile.isNotEmpty) author.mobile,
            if (author.email.isNotEmpty) author.email,
          ].join('   ·   '),
          style: const pw.TextStyle(color: _ink, fontSize: 9),
        ),
      ],
    ],
  );

  pw.Widget _rangeBox() {
    final range = report.indicativeValue;
    final summary = report.comparableSummary;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INDICATIVE MARKET RANGE',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  range == null
                      ? 'Not enough comparable sales'
                      : '${_money(range.low)} - ${_money(range.high)}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (range?.mid != null)
                  pw.Text(
                    'Midpoint ${_money(range!.mid)}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'MUNICIPAL VALUE',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _money(report.municipalValueZar),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (summary != null)
                pw.Text(
                  '${_count(summary.included)} comparable sales',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _sitePlan() {
    final svg = sitePlanSvg;
    if (svg == null) return const [];
    return [
      _heading('Site plan'),
      pw.Container(
        height: 300,
        width: double.infinity,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _rule)),
        child: pw.SvgImage(svg: svg, fit: pw.BoxFit.contain),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  /// Printable imagery only, each with its attribution directly beneath.
  List<pw.Widget> _printableImagery() => [
    for (final i in report.printableImagery)
      if (images[i.url] case final bytes?) ...[
        _heading(i.title),
        pw.Container(
          height: 250,
          width: double.infinity,
          alignment: pw.Alignment.center,
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          i.attribution,
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
        pw.SizedBox(height: 16),
      ],
  ];

  pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: _brand,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  pw.Widget _section(
    String title,
    List<(String, String)> rows, {
    String? note,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _heading(title),
          for (final (label, value) in rows)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _rule, width: 0.5),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      label,
                      style: const pw.TextStyle(color: _muted, fontSize: 9.5),
                    ),
                  ),
                  pw.Expanded(
                    flex: 6,
                    child: pw.Text(
                      value,
                      style: const pw.TextStyle(color: _ink, fontSize: 9.5),
                    ),
                  ),
                ],
              ),
            ),
          if (note != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              note,
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }

  String? _footprintNote() {
    final captured = report.buildings
        .map((b) => b.capturedPeriod)
        .whereType<String>()
        .firstOrNull;
    if (captured == null) return null;
    return 'Building footprints are from the City\'s aerial survey of $captured; '
        'later additions appear under approved building work.';
  }

  pw.Widget _approvedWork() => _section('Approved building work', [
    for (final w in report.approvedWork.take(8))
      (
        w.date ?? '-',
        [
          w.description ?? w.category ?? 'Building work',
          if (w.areaM2 != null && w.areaM2! > 0) _m2(w.areaM2),
          if (w.valueZar != null && w.valueZar! > 0) _money(w.valueZar),
        ].join(', '),
      ),
  ]);

  List<pw.Widget> _comparables() {
    final used = report.includedComparables.take(15).toList();
    if (used.isEmpty) return const [];
    final s = report.comparableSummary;
    const header = pw.TextStyle(color: PdfColors.white, fontSize: 8.5);
    const cell = pw.TextStyle(color: _ink, fontSize: 8.5);
    return [
      _heading('Comparable sales'),
      if (s != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            '${_count(s.raw)} sales recorded in the area were considered and '
            '${_count(s.included)} were used. Excluded: '
            '${_count(s.excludedZeroPrice)} transfers for R0, '
            '${_count(s.excludedImplausible)} below a plausible market price, '
            '${_count(s.excludedTooOld)} too old and '
            '${_count(s.excludedDissimilar)} too different in size. '
            'The most recent ${used.length} used are listed.',
            style: const pw.TextStyle(color: _muted, fontSize: 8.5),
          ),
        ),
      pw.TableHelper.fromTextArray(
        headers: [
          'Address',
          'Sold',
          'Price',
          'Building',
          'R/m²',
          'Indexed today',
        ],
        data: [
          for (final c in used)
            [
              titleCase(c.address),
              _month.format(c.saleDate),
              _money(c.salePriceZar),
              c.dwellingExtentM2 > 0 ? _m2(c.dwellingExtentM2) : '-',
              _money(c.pricePerDwellingM2),
              _money(c.indexedPriceZar),
            ],
        ],
        headerStyle: header,
        headerDecoration: pw.BoxDecoration(color: _brand),
        cellStyle: cell,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        border: null,
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(3.2),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(1.7),
          3: const pw.FlexColumnWidth(1.3),
          4: const pw.FlexColumnWidth(1.4),
          5: const pw.FlexColumnWidth(1.7),
        },
        cellAlignments: {
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.centerRight,
        },
      ),
      pw.SizedBox(height: 14),
    ];
  }

  pw.Widget _method() {
    final s = report.comparableSummary;
    final suburb = report.suburbStats;
    return _paragraphs('How the range was worked out', [
      report.comparablesMethod ??
          'Sales recorded by the municipality in the property\'s area were filtered: '
              'transfers for R0 and implausibly low prices (family transfers, part-transfers, '
              'correction deeds) were removed, as were sales older than four years and homes '
              'whose building size differs by more than 30%.',
      if (suburb != null && report.comparablesMethod == null)
        'Older sales were indexed to today using the suburb\'s change between the 2022 and '
            '2025 municipal rolls (${suburb.annualGrowthPercent.toStringAsFixed(1)}% a year).',
      if (s?.medianPricePerDwellingM2 != null &&
          report.dwellingExtentM2 != null &&
          report.comparablesMethod == null)
        'The median indexed price per square metre of building '
            '(${_money(s!.medianPricePerDwellingM2)}/m²) applied to this property\'s '
            '${_m2(report.dwellingExtentM2)} gives the midpoint; the lower and upper quartiles '
            'give the range.',
    ]);
  }

  pw.Widget _sources() {
    final fetched = report.provenance.isEmpty
        ? date
        : report.provenance.first.fetchedAt.toLocal();
    return _paragraphs('Sources', [
      '${report.dataSource}'
          '${report.rollVersion == null ? '' : ' and the ${report.rollVersion} general valuation roll'}'
          ', read on ${_day.format(fetched)}.',
      // One line per source, listing the figures it supplied.
      for (final source in {for (final p in report.provenance) p.source})
        '${report.provenance.where((p) => p.source == source).map((p) => p.field).join(', ')}: $source',
    ], small: true);
  }

  pw.Widget _disclaimer() => _paragraphs('Important', [
    'This report gives an indicative range from public municipal data and recorded sales. '
        'It is not a valuation by a registered valuer and should not be relied on for '
        'lending or legal purposes. Figures are as published by the municipality and may '
        'not reflect recent alterations or the condition of the property.',
  ]);

  pw.Widget _paragraphs(
    String title,
    List<String> lines, {
    bool small = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _heading(title),
        for (final l in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              l,
              style: pw.TextStyle(
                color: small ? _muted : _ink,
                fontSize: small ? 7.5 : 9,
              ),
            ),
          ),
      ],
    ),
  );
}
