import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/property_report.dart';
import 'report_fonts.dart';

/// Text for the PDF's built-in fonts, which have no typographic dashes,
/// curly quotes or ellipsis: those become their plain equivalents rather
/// than empty boxes. Use it on anything that comes from data or the agent.
String pdfText(String s) => s
    .replaceAll(RegExp('[–—−]'), '-')
    .replaceAll(RegExp('[‘’‚′]'), "'")
    .replaceAll(RegExp('[“”„″]'), '"')
    .replaceAll('…', '...')
    .replaceAll('•', '-');

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

  /// The comparable sales on a map, and the property's block (SVG).
  final String? areaMapSvg;
  final String? blockMapSvg;
  final Map<String, Uint8List> images;
  final ReportAuthor author;
  final Color brandColor;

  /// Ink on top of [brandColor] (the range box, table headers). Light brands
  /// need dark ink; defaults to white.
  final Color onBrandColor;

  /// The agency's logo (PNG or JPEG), drawn at the top of every page. Other
  /// formats, or none, fall back to the agency's name in [brandColor].
  final Uint8List? logo;
  final DateTime date;

  /// "Prepared by …" under the title; off in the report pack, which has the
  /// agent on its cover and "Your agent" page.
  final bool showAuthor;

  /// When the owners bought and for how much, as they told the agent: shown
  /// when the City's record has no sale of its own.
  final ({DateTime date, double priceZar})? ownersPurchase;

  /// The "Sources" section and the notes naming where figures come from; off
  /// in the report pack, which the agent hands over as their own.
  final bool showSources;

  ValuationReportPdf({
    required this.report,
    required this.sitePlanSvg,
    required this.images,
    required this.author,
    required this.brandColor,
    this.areaMapSvg,
    this.blockMapSvg,
    this.onBrandColor = const Color(0xFFFFFFFF),
    this.logo,
    this.showAuthor = true,
    this.ownersPurchase,
    this.showSources = true,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  /// Whether [bytes] is an image the pdf package can embed (PNG or JPEG).
  static bool isEmbeddableImage(Uint8List? bytes) =>
      bytes != null &&
      bytes.length > 8 &&
      ((bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) ||
          (bytes[0] == 0xFF && bytes[1] == 0xD8));

  static final _day = DateFormat('d MMMM yyyy');
  static final _month = DateFormat('MMM yyyy');

  static String _money(num? v) => v == null ? '-' : rand(v);
  static String _m2(num? v) => v == null ? '-' : '${groupDigits(v)} m²';
  static String _count(int v) => groupDigits(v);

  PdfColor get _brand => PdfColor.fromInt(brandColor.toARGB32());

  /// The brand colour for text and small icons on white: the brand itself
  /// when it reads well there (contrast 3:1 or more), else the agency's ink
  /// (a yellow like Rawson's is unreadable as text on white). Bands, frames
  /// and bars keep the brand colour.
  PdfColor get _brandInk => _readableOnWhite(brandColor)
      ? _brand
      : _readableOnWhite(onBrandColor)
      ? PdfColor.fromInt(onBrandColor.toARGB32())
      : const PdfColor.fromInt(0xFF1E1E1E);

  static bool _readableOnWhite(Color c) {
    double lin(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    final l = 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    return 1.05 / (l + 0.05) >= 3;
  }

  PdfColor get _onBrand => PdfColor.fromInt(onBrandColor.toARGB32());
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
      theme: await reportTheme(),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 40),
        header: _header,
        footer: _footer,
        build: (context) => content(),
      ),
    );
    return doc.save();
  }

  /// The analysis pages: the whole report as the standalone PDF prints it,
  /// reused by the report pack.
  List<pw.Widget> content() => [
    _title(),
    pw.SizedBox(height: 14),
    _rangeBox(),
    if (report.confidenceNote case final note?)
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 6),
        padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFFF6E5),
          border: pw.Border(
            left: pw.BorderSide(
              color: const PdfColor.fromInt(0xFFE0A030),
              width: 3,
            ),
          ),
        ),
        child: pw.Text(
          pdfText(note),
          style: const pw.TextStyle(fontSize: 9.5, color: _ink),
        ),
      ),
    if (showSources && report.coverageNote != null)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Text(
          pdfText(report.coverageNote!),
          style: pw.TextStyle(
            color: _muted,
            fontSize: 9.5,
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
      if (report.legalStatus != null) ('Legal status', report.legalStatus!),
      // Said either way: a sale on record, or plainly that there is none in the
      // municipality's recent sales record (older transfers are with the Deeds Office).
      if (report.lastSale case final sale?)
        (
          'Last registered sale',
          '${_day.format(sale.date)} for ${_money(sale.priceZar)}',
        )
      else if (ownersPurchase case final bought?)
        (
          'Last purchase',
          '${DateFormat('MMMM yyyy').format(bought.date)} for '
              '${_money(bought.priceZar)} (as the owners recall it)',
        )
      else if (report.municipality == 'coct')
        (
          'Last registered sale',
          "None in the City's recent sales record (older transfers are with the Deeds Office)",
        ),
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
            if (b.heightM != null) '${b.heightM!.toStringAsFixed(1)} m high',
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
    ..._salesMap(),
    ..._streetSales(),
    ..._areaMarket(),
    ..._agentSales(),
    _method(),
    _disclaimer(),
    if (showSources) _sources(),
  ];

  pw.Widget header(pw.Context context) => _header(context);

  pw.Widget footer(pw.Context context) => _footer(context);

  pw.Widget _header(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 8),
    margin: const pw.EdgeInsets.only(bottom: 14),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 2)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (isEmbeddableImage(logo))
          pw.Container(
            height: 28,
            constraints: const pw.BoxConstraints(maxWidth: 160),
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(pw.MemoryImage(logo!), fit: pw.BoxFit.contain),
          )
        else
          pw.Text(
            author.agencyName.isEmpty
                ? 'Property valuation report'
                : author.agencyName,
            style: pw.TextStyle(
              color: _brandInk,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        pw.Text(
          _day.format(date),
          style: const pw.TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );

  pw.Widget _footer(pw.Context context) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      ),
    ],
  );

  pw.Widget _title() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'PROPERTY VALUATION REPORT',
        style: pw.TextStyle(
          color: _brandInk,
          fontSize: 10,
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
        style: const pw.TextStyle(color: _muted, fontSize: 11),
      ),
      // In the report pack the agent has pages of their own.
      if (showAuthor && author.name.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Text(
          [
            'Prepared by ${author.name}',
            if (author.licenceNumber.isNotEmpty) 'FFC ${author.licenceNumber}',
            if (author.mobile.isNotEmpty) author.mobile,
            if (author.email.isNotEmpty) author.email,
          ].join('   ·   '),
          style: const pw.TextStyle(color: _ink, fontSize: 10),
        ),
      ],
    ],
  );

  pw.Widget _rangeBox() {
    final range = report.bestRange;
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
                  style: pw.TextStyle(
                    color: _onBrand,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  range == null
                      ? 'Not enough comparable sales'
                      : '${_money(range.low)} - ${_money(range.high)}',
                  style: pw.TextStyle(
                    color: _onBrand,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (range?.mid != null)
                  pw.Text(
                    'Midpoint ${_money(range!.mid)}',
                    style: pw.TextStyle(color: _onBrand, fontSize: 11),
                  ),
                if (report.rangeFromAgentSales)
                  pw.Text(
                    'From agent-reported sales, not registered transfers',
                    style: pw.TextStyle(color: _onBrand, fontSize: 9),
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
                style: pw.TextStyle(
                  color: _onBrand,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _money(report.municipalValueZar),
                style: pw.TextStyle(
                  color: _onBrand,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (summary != null)
                pw.Text(
                  '${_count(summary.included)} comparable sales',
                  style: pw.TextStyle(color: _onBrand, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _sitePlan() {
    final block = blockMapSvg;
    // The site plan is only worth its space with the buildings on it; an
    // outline alone says less than the block view beside it.
    final plan = block != null && report.buildings.isEmpty ? null : sitePlanSvg;
    if (plan == null && block == null) return const [];
    pw.Widget frame(String svg, double height) => pw.Container(
      height: height,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _rule)),
      child: pw.SvgImage(svg: svg, fit: pw.BoxFit.cover),
    );
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _heading(
              block == null
                  ? 'Site plan'
                  : 'The property and its neighbourhood',
            ),
            if (block != null && plan != null)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 3, child: frame(block, 230)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      height: 230,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _rule),
                      ),
                      child: pw.SvgImage(svg: plan, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              )
            else
              frame(block ?? plan!, block != null ? 360 : 300),
          ],
        ),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  /// Where the comparable sales are: numbered as in the table, in the radius
  /// they were drawn from.
  List<pw.Widget> _salesMap() {
    final svg = areaMapSvg;
    if (svg == null || report.includedComparables.isEmpty) return const [];
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _heading('Where the comparable sales are'),
            pw.Container(
              height: 470,
              width: double.infinity,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _rule)),
              child: pw.SvgImage(svg: svg, fit: pw.BoxFit.contain),
            ),
          ],
        ),
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
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
        pw.SizedBox(height: 16),
      ],
  ];

  pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: _brandInk,
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
    // Inseparable: a short section moves to the next page whole, so its
    // heading is never left alone at the bottom of a page.
    return pw.Inseparable(
      child: pw.Padding(
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
                        style: const pw.TextStyle(
                          color: _muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 6,
                      child: pw.Text(
                        value,
                        style: const pw.TextStyle(color: _ink, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ),
            if (note != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                note,
                style: const pw.TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _footprintNote() {
    final captured = report.buildings
        .map((b) => b.capturedPeriod)
        .whereType<String>()
        .firstOrNull;
    if (captured == null) return null;
    return showSources
        ? 'Building footprints are from the City\'s aerial survey of $captured; '
              'later additions appear under approved building work.'
        : 'Building footprints date from $captured; later additions appear '
              'under approved building work.';
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
    final used = report.listedComparables.take(15).toList();
    final usedCount = used.where((c) => c.included).length;
    if (usedCount == 0) return const [];
    final withDistance = used.any((c) => c.distanceM != null);
    final s = report.comparableSummary;
    final header = pw.TextStyle(color: _onBrand, fontSize: 9.5);
    const cell = pw.TextStyle(color: _ink, fontSize: 9.5);
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
            '${s.radiusM != null ? 'The comparables are the sales within ${s.radiusM} m of the property. ' : ''}'
            'The most recent $usedCount used are listed'
            '${used.length > usedCount ? ', then the next ${used.length - usedCount} most alike for reference (in grey; not used for the range)' : ''}.',
            style: const pw.TextStyle(color: _muted, fontSize: 9.5),
          ),
        ),
      pw.TableHelper.fromTextArray(
        headers: [
          if (areaMapSvg != null) '#',
          'Address',
          if (withDistance) 'Dist',
          'Sold',
          'Price',
          'Building',
          'R/m²',
          'Indexed today',
        ],
        data: [
          for (final (i, c) in used.indexed)
            [
              if (areaMapSvg != null) '${i + 1}',
              titleCase(report.withoutSuburb(c.address)),
              if (withDistance)
                c.distanceM == null ? '-' : '${c.distanceM!.round()} m',
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
        // Sales listed for reference in grey.
        textStyleBuilder: (_, _, row) =>
            row > usedCount ? cell.copyWith(color: _muted) : cell,
        columnWidths: {
          for (final (i, w) in [
            if (areaMapSvg != null) 0.6, // room for "10"
            3.1,
            if (withDistance) 0.9,
            1.3,
            1.7,
            1.3,
            1.4,
            1.7,
          ].indexed)
            i: pw.FlexColumnWidth(w),
        },
        // Numbers to the right: distance, price, building, R/m², indexed.
        cellAlignments: () {
          final first = areaMapSvg != null ? 1 : 0; // the address column
          final sold = first + (withDistance ? 2 : 1);
          return {
            if (withDistance) first + 1: pw.Alignment.centerRight,
            for (var i = sold + 1; i <= sold + 4; i++)
              i: pw.Alignment.centerRight,
          };
        }(),
      ),
      pw.SizedBox(height: 14),
    ];
  }

  /// Sales agents reported in the suburb, with how each is known. Never names
  /// the agent who reported it.
  List<pw.Widget> _agentSales() {
    final agent = report.agentSales;
    if (agent == null || agent.sales.isEmpty) return const [];
    final shown = agent.sales.take(15).toList();
    final header = pw.TextStyle(color: _onBrand, fontSize: 9.5);
    const cell = pw.TextStyle(color: _ink, fontSize: 9.5);
    return [
      _heading('Sales reported by agents'),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          pdfText(agent.evidenceStatement),
          style: const pw.TextStyle(color: _muted, fontSize: 9.5),
        ),
      ),
      pw.TableHelper.fromTextArray(
        headers: ['Address', 'Sold', 'Price', 'Floor', 'R/m²', 'How known'],
        data: [
          for (final a in shown)
            [
              [
                titleCase(report.withoutSuburb(a.address)),
                if (a.homeSummary.isNotEmpty) a.homeSummary,
              ].join('\n'),
              _month.format(a.saleDate),
              _money(a.salePriceZar),
              a.floorM2 == null ? '-' : _m2(a.floorM2!),
              _money(a.pricePerFloorM2),
              [
                a.evidenceText,
                if (a.corroborationCount > 0)
                  'confirmed by ${a.corroborationCount + 1} agents',
                if (a.isDisputed) 'not used: municipal record differs',
              ].join('; '),
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
          0: const pw.FlexColumnWidth(2.8),
          1: const pw.FlexColumnWidth(1.2),
          2: const pw.FlexColumnWidth(1.6),
          3: const pw.FlexColumnWidth(1.1),
          4: const pw.FlexColumnWidth(1.3),
          5: const pw.FlexColumnWidth(2.6),
        },
        cellAlignments: {
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
      ),
      pw.SizedBox(height: 14),
    ];
  }

  /// The subject's street name, e.g. "Bosman Street".
  String? get _street {
    final line = report.address.toUpperCase().trim();
    final withoutNumber = line.replaceFirst(RegExp(r'^\d+[A-Z]?\s+'), '');
    final suburb = report.suburb.toUpperCase();
    final street = withoutNumber.endsWith(' $suburb')
        ? withoutNumber.substring(0, withoutNumber.length - suburb.length - 1)
        : withoutNumber;
    return street.isEmpty || street.startsWith('ERF ')
        ? null
        : titleCase(street);
  }

  /// The latest sales in the subject's own street.
  List<pw.Widget> _streetSales() {
    final sales = report.streetSales;
    if (sales.isEmpty) return const [];
    return [
      _heading('Recent sales in ${_street ?? 'the street'}'),
      _table(
        ['Address', 'Sold', 'Price', 'Erf', 'Building', 'R/m²'],
        [
          for (final c in sales)
            [
              titleCase(c.address),
              _month.format(c.saleDate),
              _money(c.salePriceZar),
              c.erfExtentM2 > 0 ? _m2(c.erfExtentM2) : '-',
              c.dwellingExtentM2 > 0 ? _m2(c.dwellingExtentM2) : '-',
              _money(c.pricePerDwellingM2),
            ],
        ],
        widths: [3.2, 1.3, 1.7, 1.2, 1.2, 1.3],
        rightFrom: 2,
      ),
      pw.SizedBox(height: 14),
    ];
  }

  /// The area's market: sales by year and how prices spread, as bar charts.
  List<pw.Widget> _areaMarket() {
    final m = report.areaMarket;
    if (m == null || m.sales == 0) return const [];
    final where = m.radiusM != null
        ? 'within ${m.radiusM} m of the property'
        : 'in the area';
    final median = m.medianPriceZar == null
        ? ''
        : ', median ${_money(m.medianPriceZar)}';
    // The band the property's indicative value falls in.
    final value = report.bestRange?.mid ?? report.municipalValueZar;
    final own = value == null
        ? -1
        : m.priceBands.indexWhere((b) => value >= b.fromZar && value < b.toZar);
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _heading('The market around the property'),
            pw.Text(
              '${_count(m.sales)} market sales $where$median.',
              style: const pw.TextStyle(color: _muted, fontSize: 9.5),
            ),
            pw.SizedBox(height: 8),
            _chartCard(
              'What homes sold for',
              own >= 0
                  ? 'Share of sales in each price range; your home\'s range is highlighted'
                  : 'Share of sales in each price range',
              _bars(
                [
                  for (final b in m.priceBands)
                    ('${_short(b.fromZar)} -\n${_short(b.toZar)}', b.percent),
                ],
                highlight: own,
                highlightLabel: 'your home',
                unit: '%',
                height: 110,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: _chartCard(
                    'Sales by year',
                    'Bars: number of sales · line: median price',
                    _yearChart(m.byYear),
                  ),
                ),
                if (value != null && m.priceBands.isNotEmpty) ...[
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 4,
                    child: _chartCard(
                      'Where this home sits',
                      'Against the prices paid around it',
                      _valueScale(m),
                    ),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 14),
          ],
        ),
      ),
    ];
  }

  /// "R 2.7m", "R 850k".
  static String _short(num v) => v >= 1000000
      ? 'R ${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}m'
      : 'R ${(v / 1000).round()}k';

  /// Chart colour: the brand, or its ink when the brand is too light to
  /// read on white (a pale yellow bar is barely visible).
  PdfColor get _chart => _brandInk;

  PdfColor _tint(double amount) => PdfColor(
    1 - (1 - _chart.red) * amount,
    1 - (1 - _chart.green) * amount,
    1 - (1 - _chart.blue) * amount,
  );

  pw.Widget _chartCard(String title, String subtitle, pw.Widget chart) =>
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rule),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              pdfText(subtitle),
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
            pw.SizedBox(height: 8),
            chart,
          ],
        ),
      );

  /// Rounded, shaded bars with their values; [highlight] in the full brand
  /// colour with a tag, the rest lighter.
  pw.Widget _bars(
    List<(String, double)> bars, {
    int highlight = -1,
    String? highlightLabel,
    String unit = '',
    double height = 90,
  }) {
    final max = bars.fold<double>(0, (m, b) => b.$2 > m ? b.$2 : m);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (final (i, (label, value)) in bars.indexed)
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (i == highlight && highlightLabel != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 2),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _chart,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        highlightLabel,
                        style: pw.TextStyle(color: _onBrand, fontSize: 6.5),
                      ),
                    ),
                  pw.Text(
                    '${value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(1)}$unit',
                    style: pw.TextStyle(
                      color: i == highlight ? _brand : _muted,
                      fontSize: 7.5,
                      fontWeight: i == highlight ? pw.FontWeight.bold : null,
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Container(
                    height: max == 0
                        ? 0
                        : (height * value / max).clamp(1.5, height),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.vertical(
                        top: pw.Radius.circular(3),
                      ),
                      gradient: pw.LinearGradient(
                        begin: pw.Alignment.topCenter,
                        end: pw.Alignment.bottomCenter,
                        colors: i == highlight || highlight < 0
                            ? [_tint(0.8), _chart]
                            : [_tint(0.3), _tint(0.5)],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    label,
                    style: pw.TextStyle(
                      color: i == highlight ? _brand : _ink,
                      fontSize: 6.5,
                      fontWeight: i == highlight ? pw.FontWeight.bold : null,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Sales per year as bars, the median price as a line over them.
  pw.Widget _yearChart(List<YearlySales> years) {
    if (years.isEmpty) return pw.SizedBox();
    const height = 80.0;
    final maxSales = years.fold<int>(1, (m, y) => y.sales > m ? y.sales : m);
    final prices = years.map((y) => y.medianPriceZar).toList();
    final lo = prices.reduce((a, b) => a < b ? a : b) * 0.9;
    final hi = prices.reduce((a, b) => a > b ? a : b) * 1.08;
    return pw.Column(
      children: [
        pw.SizedBox(
          height: height,
          child: pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.CustomPaint(
                  painter: (PdfGraphics g, PdfPoint size) {
                    final slot = size.x / years.length;
                    g.setFillColor(_tint(0.35));
                    for (var i = 0; i < years.length; i++) {
                      final h = years[i].sales / maxSales * size.y * 0.8;
                      g.drawRRect(
                        slot * i + slot * 0.18,
                        0,
                        slot * 0.64,
                        h,
                        3,
                        3,
                      );
                    }
                    g.fillPath();
                    double y(double price) => hi == lo
                        ? size.y / 2
                        : (price - lo) / (hi - lo) * size.y;
                    g.setStrokeColor(_brand);
                    g.setLineWidth(2);
                    for (var i = 0; i < years.length; i++) {
                      final x = slot * i + slot / 2;
                      if (i == 0) {
                        g.moveTo(x, y(prices[i]));
                      } else {
                        g.lineTo(x, y(prices[i]));
                      }
                    }
                    g.strokePath();
                    g.setFillColor(_brand);
                    for (var i = 0; i < years.length; i++) {
                      g.drawEllipse(
                        slot * i + slot / 2,
                        y(prices[i]),
                        2.4,
                        2.4,
                      );
                    }
                    g.fillPath();
                  },
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            for (final yr in years)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${yr.year}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${yr.sales} sales',
                      style: const pw.TextStyle(fontSize: 6.5, color: _muted),
                    ),
                    pw.Text(
                      _short(yr.medianPriceZar),
                      style: pw.TextStyle(fontSize: 7, color: _brandInk),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// A scale from the lowest to the highest price paid nearby, with this
  /// home's range, the area's median and the municipal value marked.
  pw.Widget _valueScale(AreaMarket m) {
    // Wide enough for this home and the municipal value, even when they lie
    // beyond every sale nearby.
    final range = report.bestRange;
    final points = [
      m.priceBands.first.fromZar,
      m.priceBands.last.toZar,
      ?range?.low,
      ?range?.high,
      ?report.municipalValueZar,
    ];
    final lo = points.reduce((a, b) => a < b ? a : b);
    final hi = points.reduce((a, b) => a > b ? a : b) * 1.03;
    double at(double v) => ((v - lo) / (hi - lo)).clamp(0.0, 1.0);
    final marks = <(String, double, PdfColor)>[
      if (m.medianPriceZar case final med?) ('Area median', med, _muted),
      if (report.municipalValueZar case final mv?)
        ('Municipal value', mv, _ink),
    ];
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints!.maxWidth;
        return pw.SizedBox(
          height: 96,
          child: pw.Stack(
            children: [
              // The scale.
              pw.Positioned(
                left: 0,
                right: 0,
                top: 40,
                child: pw.Container(
                  height: 8,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(4),
                    gradient: pw.LinearGradient(
                      colors: [_tint(0.12), _tint(0.45)],
                    ),
                  ),
                ),
              ),
              // This home's indicative range, on the scale.
              if (range?.low != null && range?.high != null)
                pw.Positioned(
                  left: w * at(range!.low!),
                  top: 37,
                  child: pw.Container(
                    width: (w * (at(range.high!) - at(range.low!))).clamp(6, w),
                    height: 14,
                    decoration: pw.BoxDecoration(
                      color: _chart,
                      borderRadius: pw.BorderRadius.circular(7),
                    ),
                  ),
                ),
              if (range?.mid != null)
                pw.Positioned(
                  left: (w * at(range!.mid!) - 40).clamp(0, w - 80),
                  top: 12,
                  child: pw.SizedBox(
                    width: 80,
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'This home',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: _brandInk,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _short(range.mid!),
                          style: pw.TextStyle(fontSize: 8, color: _brandInk),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final (i, (label, v, colour)) in marks.indexed) ...[
                pw.Positioned(
                  left: w * at(v) - 0.75,
                  top: 36,
                  child: pw.Container(width: 1.5, height: 16, color: colour),
                ),
                pw.Positioned(
                  left: (w * at(v) - 40).clamp(0, w - 80),
                  top: 56 + i * 16.0,
                  child: pw.SizedBox(
                    width: 80,
                    child: pw.Text(
                      '$label ${_short(v)}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 7.5, color: colour),
                    ),
                  ),
                ),
              ],
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Text(
                  _short(lo),
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ),
              pw.Positioned(
                right: 0,
                top: 0,
                child: pw.Text(
                  _short(hi),
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A brand-headed table; columns from [rightFrom] on are right-aligned.
  pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    required List<double> widths,
    int rightFrom = 99,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(color: _onBrand, fontSize: 9.5),
    headerDecoration: pw.BoxDecoration(color: _brand),
    cellStyle: const pw.TextStyle(color: _ink, fontSize: 9.5),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    border: null,
    rowDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
    ),
    columnWidths: {
      for (final (i, w) in widths.indexed) i: pw.FlexColumnWidth(w),
    },
    cellAlignments: {
      for (var i = rightFrom; i < headers.length; i++)
        i: pw.Alignment.centerRight,
    },
  );

  pw.Widget _method() {
    final s = report.comparableSummary;
    final suburb = report.suburbStats;
    if (report.rangeFromAgentSales) {
      return _paragraphs('How the range was worked out', [
        'No municipal sales record is available for this area, so the range '
            'comes from sales reported by agents working in '
            '${titleCase(report.suburb)}. Each sale is weighted by how it is '
            'known (an agent\'s own sale or a signed offer counts more than '
            'hearsay); the weighted median price per square metre of '
            '${report.agentSales!.indicativeBasis == 'floor' ? 'floor' : 'erf'} '
            'applied to this property gives the midpoint, and the weighted '
            'quartiles the range.',
      ]);
    }
    return _paragraphs('How the range was worked out', [
      (report.comparablesMethod == null
              ? null
              : pdfText(report.comparablesMethod!)) ??
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
      if (report.sizedFromListingM2 case final floor?)
        'Each sale was carried to the ${_m2(floor)} floor area captured on the listing'
            '${report.dwellingExtentM2 == null ? '' : ' (the City records ${_m2(report.dwellingExtentM2)})'}; '
            'the midpoint is their median and the range their middle half.'
            '${report.cityRange?.low != null && report.cityRange?.high != null ? ' On the City\'s ${_m2(report.dwellingExtentM2)} the range would be ${_money(report.cityRange!.low)} to ${_money(report.cityRange!.high)}.' : ''}',
    ]);
  }

  pw.Widget _sources() {
    final fetched = report.provenance.isEmpty
        ? date
        : report.provenance.first.fetchedAt.toLocal();
    return _paragraphs('Sources', [
      '${pdfText(report.dataSource)}'
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
    if (report.agentSales?.sales.isNotEmpty ?? false)
      'Sales reported by agents are as the agents know them and are not '
          'registered transfers; each is weighted by how it is known, and a '
          'price the municipal record contradicts is not used.',
  ]);

  pw.Widget _paragraphs(
    String title,
    List<String> lines, {
    bool small = false,
  }) => pw.Inseparable(
    child: pw.Padding(
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
    ),
  );
}
