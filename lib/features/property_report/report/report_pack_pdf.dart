import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/office_details.dart';
import '../data/models/area_details.dart';
import '../data/models/property_report.dart';
import 'costs_calculator.dart';
import 'valuation_report_pdf.dart';

/// Who the pack is from: printed on the cover, the "Your agent" page and the
/// letter.
class PackAgent {
  final String name;
  final String jobTitle;
  final String email;
  final String mobile;
  final String website;
  final String ppraNumber;
  final String ffcNumber;
  final String bio;
  final List<String> qualifications;
  final String agencyName;

  /// The agent's office, already merged with the agency's defaults.
  final OfficeDetails office;

  const PackAgent({
    required this.name,
    this.jobTitle = '',
    this.email = '',
    this.mobile = '',
    this.website = '',
    this.ppraNumber = '',
    this.ffcNumber = '',
    this.bio = '',
    this.qualifications = const [],
    this.agencyName = '',
    this.office = const OfficeDetails(),
  });
}

/// What the agent captured about the home, for the cover's "Property
/// portfolio" and the letter.
class PackListing {
  /// "Mr & Mrs Du Toit": who the pack is prepared for.
  final String preparedFor;

  /// The owners' first names for the letter's greeting, e.g. "Francois & Ree".
  final String greeting;
  final List<String> portfolio;

  const PackListing({
    this.preparedFor = '',
    this.greeting = '',
    this.portfolio = const [],
  });
}

/// The agent's conclusions, entered before the pack is made.
class PackValuation {
  final double low;
  final double high;
  final double listingPrice;
  const PackValuation({
    required this.low,
    required this.high,
    required this.listingPrice,
  });
}

/// Pictures for the pack, fetched beforehand (PNG or JPEG bytes).
class PackImages {
  final Uint8List? coverPhoto;
  final Uint8List? secondPhoto;
  final Uint8List? agentPhoto;
  final Uint8List? signature;
  final Uint8List? logo;

  /// Property24 listing photos by listing number.
  final Map<String, Uint8List> listingPhotos;
  final List<Uint8List> brochurePages;

  const PackImages({
    this.coverPhoto,
    this.secondPhoto,
    this.agentPhoto,
    this.signature,
    this.logo,
    this.listingPhotos = const {},
    this.brochurePages = const [],
  });
}

/// The full report pack: cover, contents, the agent, the valuation analysis,
/// area details, homes on the market, the valuation letter, costs to seller
/// and buyer, and the agency's brochure pages. One PDF, in the agency's brand.
///
/// The same licence rules as [ValuationReportPdf] apply (it draws the
/// analysis): only printable imagery, no owner data from registers. The
/// owners' names come from the agent's own listing.
class ReportPackPdf {
  final PropertyReport report;
  final String? sitePlanSvg;
  final Map<String, Uint8List> images;
  final PackAgent agent;
  final PackListing listing;
  final PackValuation valuation;
  final CostsSummary costs;
  final AreaDetails? area;
  final ForSale? forSale;
  final PackImages pictures;
  final Color brandColor;
  final Color onBrandColor;
  final DateTime date;

  ReportPackPdf({
    required this.report,
    required this.sitePlanSvg,
    required this.images,
    required this.agent,
    required this.listing,
    required this.valuation,
    required this.costs,
    required this.pictures,
    required this.brandColor,
    this.onBrandColor = const Color(0xFFFFFFFF),
    this.area,
    this.forSale,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  static final _day = DateFormat('d MMMM yyyy');
  static final _shortDay = DateFormat('d MMM yyyy');
  static const _ink = PdfColor.fromInt(0xFF1E1E1E);
  static const _muted = PdfColor.fromInt(0xFF6B6F76);
  static const _rule = PdfColor.fromInt(0xFFDDDFE3);
  static const _margin = pw.EdgeInsets.fromLTRB(40, 36, 40, 40);

  PdfColor get _brand => PdfColor.fromInt(brandColor.toARGB32());
  PdfColor get _onBrand => PdfColor.fromInt(onBrandColor.toARGB32());

  String get fileName =>
      'Valuation - ${report.displayAddress.replaceAll(',', '')}.pdf';

  static pw.ImageProvider? _img(Uint8List? bytes) =>
      ValuationReportPdf.isEmbeddableImage(bytes)
      ? pw.MemoryImage(bytes!)
      : null;

  late final ValuationReportPdf _analysis = ValuationReportPdf(
    report: report,
    sitePlanSvg: sitePlanSvg,
    images: images,
    author: ReportAuthor(
      name: agent.name,
      agencyName: agent.agencyName,
      email: agent.email,
      mobile: agent.mobile,
      licenceNumber: agent.ffcNumber,
    ),
    brandColor: brandColor,
    onBrandColor: onBrandColor,
    logo: pictures.logo,
    date: date,
  );

  bool get _hasArea => area != null && !area!.isEmpty;
  bool get _hasMarket => forSale?.listings.isNotEmpty ?? false;

  /// The sections, in order, for the contents page and the letter.
  List<String> get sections => [
    'Your agent',
    'Market valuation analysis',
    if (_hasArea) 'Area details',
    if (_hasMarket) 'Homes on the market like yours',
    'Valuation letter',
    'Costs to seller and buyer',
    if (pictures.brochurePages.isNotEmpty) 'About ${agent.agencyName}',
  ];

  Future<Uint8List> build() async {
    final doc = pw.Document(
      title: 'Valuation - ${report.displayAddress}',
      author: agent.name.isEmpty ? null : agent.name,
      creator: 'RealWorth',
    );
    final format = PdfPageFormat.a4;

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => _cover(),
      ),
    );
    doc.addPage(
      pw.Page(pageFormat: format, margin: _margin, build: (_) => _contents()),
    );
    doc.addPage(
      pw.Page(pageFormat: format, margin: _margin, build: (_) => _agentPage()),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: _margin,
        header: _analysis.header,
        footer: _analysis.footer,
        build: (_) => [
          _sectionTitle('Market valuation analysis'),
          ..._analysis.content(),
        ],
      ),
    );
    if (_hasArea) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: _margin,
          header: _analysis.header,
          footer: _analysis.footer,
          build: (_) => _areaPage(area!),
        ),
      );
    }
    if (_hasMarket) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: _margin,
          header: _analysis.header,
          footer: _analysis.footer,
          build: (_) => _marketPage(forSale!),
        ),
      );
    }
    doc.addPage(
      pw.Page(pageFormat: format, margin: _margin, build: (_) => _letter()),
    );
    doc.addPage(
      pw.Page(pageFormat: format, margin: _margin, build: (_) => _costsPage()),
    );
    for (final page in pictures.brochurePages) {
      final image = _img(page);
      if (image == null) continue;
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.contain),
        ),
      );
    }
    return doc.save();
  }

  // ---- cover ---------------------------------------------------------------

  pw.Widget _cover() {
    final cover = _img(pictures.coverPhoto) ?? _img(_satellite);
    final second = _img(pictures.secondPhoto);
    final satellite = _img(_satellite);
    final sold = report.lastSale;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 14),
          child: pw.Column(
            children: [
              pw.Text(
                'Market Related Property Valuation',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${report.displayAddress}  //  Erf ${report.erf}',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (listing.preparedFor.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _brand, width: 1),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    pdfText('Specially prepared for ${listing.preparedFor}.'),
                    style: pw.TextStyle(fontSize: 12, color: _brand),
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.Container(
          height: 300,
          color: _brand,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: cover == null
              ? pw.Center(
                  child: pw.Text(
                    report.displayAddress,
                    style: pw.TextStyle(color: _onBrand, fontSize: 18),
                  ),
                )
              : pw.Image(cover, fit: pw.BoxFit.cover),
        ),
        if (sold != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Center(
              child: pw.Text(
                'Last registered sale: ${_day.format(sold.date)} for ${rand(sold.priceZar)}',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        pw.SizedBox(height: 10),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 40),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          for (final i in [
                            satellite,
                            second,
                          ].whereType<pw.ImageProvider>())
                            pw.Expanded(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 6),
                                child: pw.SizedBox(
                                  height: 90,
                                  child: pw.Image(i, fit: pw.BoxFit.cover),
                                ),
                              ),
                            ),
                        ],
                      ),
                      pw.Spacer(),
                      pw.Text(
                        'Thank you for allowing me the opportunity to present our market related property '
                        'valuation to you.',
                        style: pw.TextStyle(fontSize: 12, color: _brand),
                      ),
                      pw.SizedBox(height: 10),
                      _agentCard(),
                      pw.SizedBox(height: 16),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Property portfolio',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      for (final line in _portfolio)
                        pw.Bullet(
                          text: pdfText(line),
                          style: const pw.TextStyle(fontSize: 8.5, color: _ink),
                          margin: const pw.EdgeInsets.only(bottom: 2),
                          bulletColor: _brand,
                          bulletSize: 3,
                        ),
                      pw.Spacer(),
                      if (_img(pictures.logo) case final logo?)
                        pw.Align(
                          alignment: pw.Alignment.bottomRight,
                          child: pw.SizedBox(
                            height: 36,
                            child: pw.Image(logo, fit: pw.BoxFit.contain),
                          ),
                        ),
                      pw.SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Uint8List? get _satellite {
    for (final i in report.printableImagery) {
      if (images[i.url] case final bytes?) return bytes;
    }
    return null;
  }

  /// The listing's own portfolio first, then what the records add.
  List<String> get _portfolio => [
    if (report.zoningDescription != null)
      'Zoned: ${[report.zoningCode, report.zoningDescription].whereType<String>().join(' - ')}',
    if (report.extentM2 != null)
      'Erf size: ${groupDigits(report.extentM2!)} m²',
    ...listing.portfolio,
  ];

  pw.Widget _agentCard() {
    final photo = _img(pictures.agentPhoto);
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      color: _brand,
      child: pw.Row(
        children: [
          if (photo != null)
            pw.Container(
              width: 58,
              height: 64,
              margin: const pw.EdgeInsets.only(right: 10),
              child: pw.Image(photo, fit: pw.BoxFit.cover),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  agent.name,
                  style: pw.TextStyle(
                    color: _onBrand,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (agent.jobTitle.isNotEmpty)
                  pw.Text(
                    agent.jobTitle,
                    style: pw.TextStyle(color: _onBrand, fontSize: 8),
                  ),
                pw.SizedBox(height: 3),
                for (final line in [
                  if (agent.mobile.isNotEmpty) 'M: ${agent.mobile}',
                  if (agent.email.isNotEmpty) 'E: ${agent.email}',
                  if (agent.website.isNotEmpty) 'W: ${agent.website}',
                ])
                  pw.Text(
                    line,
                    style: pw.TextStyle(color: _onBrand, fontSize: 7.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- contents and letterhead ---------------------------------------------

  pw.Widget _letterhead() {
    final logo = _img(pictures.logo);
    final office = agent.office;
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 18),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 1.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          logo == null
              ? pw.Text(
                  agent.agencyName,
                  style: pw.TextStyle(
                    color: _brand,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                )
              : pw.SizedBox(
                  height: 44,
                  width: 190,
                  child: pw.Image(
                    logo,
                    fit: pw.BoxFit.contain,
                    alignment: pw.Alignment.centerLeft,
                  ),
                ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final line in [
                if (office.name.isNotEmpty) office.name,
                if (office.address.isNotEmpty) office.address,
                if (office.phone.isNotEmpty) 'Tel: ${office.phone}',
                if (office.website.isNotEmpty) office.website,
              ])
                pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 7.5, color: _ink),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _officeFooter() => agent.office.footer.isEmpty
      ? pw.SizedBox()
      : pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _brand, width: 1)),
          ),
          child: pw.Center(
            child: pw.Text(
              pdfText(agent.office.footer),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ),
        );

  pw.Widget _contents() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _letterhead(),
      pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              'MARKET RELATED VALUATION REPORT',
              style: pw.TextStyle(fontSize: 20, color: _brand),
            ),
            pw.Text(
              'Contents',
              style: const pw.TextStyle(fontSize: 18, color: _ink),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 30),
      for (final (i, s) in sections.indexed)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 7),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 28,
                child: pw.Text(
                  '${i + 1}',
                  style: pw.TextStyle(color: _brand, fontSize: 12),
                ),
              ),
              pw.Text(s, style: pw.TextStyle(color: _ink, fontSize: 13)),
            ],
          ),
        ),
      pw.Spacer(),
      _officeFooter(),
    ],
  );

  pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 18,
        color: _brand,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  // ---- your agent ------------------------------------------------------------

  pw.Widget _agentPage() {
    final photo = _img(pictures.agentPhoto);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _letterhead(),
        pw.Text(
          'YOUR AGENT',
          style: pw.TextStyle(fontSize: 12, color: _muted, letterSpacing: 2),
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (photo != null)
              pw.Container(
                width: 150,
                height: 180,
                margin: const pw.EdgeInsets.only(right: 20),
                child: pw.Image(photo, fit: pw.BoxFit.cover),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    agent.name,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (agent.jobTitle.isNotEmpty)
                    pw.Text(
                      agent.jobTitle,
                      style: const pw.TextStyle(fontSize: 13, color: _ink),
                    ),
                  pw.SizedBox(height: 10),
                  for (final line in [
                    agent.email,
                    agent.website,
                    agent.mobile,
                  ].where((l) => l.isNotEmpty))
                    pw.Text(
                      line,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _brand,
                        letterSpacing: 0.6,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (agent.bio.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text(
            pdfText(agent.bio),
            style: const pw.TextStyle(
              fontSize: 10.5,
              color: _ink,
              lineSpacing: 3,
            ),
          ),
        ],
        if (agent.qualifications.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Qualifications & registrations',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 4),
          for (final q in agent.qualifications)
            pw.Bullet(
              text: pdfText(q),
              style: const pw.TextStyle(fontSize: 9.5, color: _ink),
              bulletColor: _brand,
              bulletSize: 3,
            ),
        ],
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 18,
          children: [
            if (agent.ppraNumber.isNotEmpty)
              pw.Text(
                'PPRA reg. no. ${agent.ppraNumber}',
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            if (agent.ffcNumber.isNotEmpty)
              pw.Text(
                'FFC no. ${agent.ffcNumber}',
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
          ],
        ),
        pw.Spacer(),
        pw.Container(
          width: double.infinity,
          color: _brand,
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Center(
            child: pw.Text(
              'registered professional property practitioner',
              style: pw.TextStyle(
                color: _onBrand,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        _officeFooter(),
      ],
    );
  }

  // ---- area details -----------------------------------------------------------

  List<pw.Widget> _areaPage(AreaDetails a) {
    pw.Widget facts(
      String title,
      List<(String, String)> rows, {
      String? note,
    }) => pw.Inseparable(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                color: _brand,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            for (final (label, value) in rows)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _rule, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        pdfText(label),
                        style: const pw.TextStyle(fontSize: 9, color: _muted),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        pdfText(value),
                        style: const pw.TextStyle(fontSize: 9, color: _ink),
                      ),
                    ),
                  ],
                ),
              ),
            if (note != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  pdfText(note),
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                ),
              ),
          ],
        ),
      ),
    );

    final p = a.population;
    final c = a.crime;
    final w = a.climate;
    final income = a.income;
    return [
      _sectionTitle('Area details'),
      if (p != null)
        facts('Population', [
          if (p.subPlace != null)
            (
              'Neighbourhood',
              '${p.subPlace}${p.mainPlace == null ? '' : ', ${p.mainPlace}'}',
            ),
          if (p.estimatedPopulation != null)
            (
              'People (${p.estimateYear} estimate)',
              groupDigits(p.estimatedPopulation!),
            ),
          if (p.population != null)
            ('People (Census ${p.year})', groupDigits(p.population!)),
          if (p.households != null)
            ('Households (Census ${p.year})', groupDigits(p.households!)),
          if (p.areaKm2 != null)
            ('Area', '${p.areaKm2!.toStringAsFixed(2)} km²'),
          if (p.peoplePerKm2 != null)
            ('Density', '${groupDigits(p.peoplePerKm2!)} people per km²'),
        ], note: [p.source, p.estimateSource].whereType<String>().join('; ')),
      if (c != null)
        facts(
          'Crime: ${c.precinct} police precinct',
          [
            for (final x in c.crimes)
              (
                x.crime,
                '${groupDigits(x.count)}  (previous year ${groupDigits(x.previousCount)})',
              ),
            (
              'All community-reported serious crime',
              '${groupDigits(c.total)}${c.change == null ? '' : '  (${c.change! >= 0 ? '+' : ''}${c.change!.toStringAsFixed(0)}% on the year before)'}',
            ),
            if (c.totalPer100k != null)
              ('Per 100 000 residents', groupDigits(c.totalPer100k!)),
            if (c.band != null) ('Compared with all precincts', c.band!),
          ],
          note:
              '${c.period}. Figures are for the whole police precinct; precincts that include a town centre, '
              'beachfront or shopping area count crimes against visitors too, so their rate per resident reads '
              'higher. ${c.source}.',
        ),
      if (income != null)
        facts(
          'Household income (${income.municipality})',
          [
            ('The middle household earns', income.medianBand),
            for (final b in income.bands.where((b) => b.percent >= 8))
              (b.label, '${b.percent.toStringAsFixed(1)}% of households'),
          ],
          note:
              '${income.source}, whole municipality. Census 2022 income has not been released.',
        ),
      if (w != null)
        facts(
          pdfText('Climate (${w.years})'),
          [
            ('Average temperature', '${w.meanC.toStringAsFixed(1)} °C'),
            (
              'Average daily high / low',
              '${w.avgMaxC.toStringAsFixed(1)} °C / ${w.avgMinC.toStringAsFixed(1)} °C',
            ),
            (
              'Hottest month',
              '${w.hottestMonth} (average high ${w.hottestAvgMaxC.toStringAsFixed(1)} °C)',
            ),
            (
              'Coldest month',
              '${w.coldestMonth} (average low ${w.coldestAvgMinC.toStringAsFixed(1)} °C)',
            ),
            ('Rainfall', '${groupDigits(w.annualRainMm)} mm a year'),
            if (w.humidityPct != null)
              ('Humidity', '${w.humidityPct!.round()}% on average'),
          ],
          note:
              '${w.source}: a regional climate average (about 50 km), not a street-level reading.',
        ),
    ];
  }

  // ---- homes on the market ------------------------------------------------------

  List<pw.Widget> _marketPage(ForSale f) {
    return [
      _sectionTitle('Homes on the market like yours'),
      pw.Text(
        pdfText(
          'Currently advertised on Property24 near ${report.displayAddress}. ${f.attribution}',
        ),
        style: const pw.TextStyle(fontSize: 8.5, color: _muted),
      ),
      pw.SizedBox(height: 10),
      for (final l in f.listings)
        pw.Inseparable(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _rule, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (_img(pictures.listingPhotos[l.listingNumber])
                    case final photo?)
                  pw.Container(
                    width: 190,
                    height: 125,
                    margin: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(photo, fit: pw.BoxFit.cover),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (l.listedOn != null)
                        pw.Text(
                          'Listed ${_shortDay.format(l.listedOn!)}',
                          style: const pw.TextStyle(fontSize: 8, color: _muted),
                        ),
                      pw.Text(
                        l.priceZar == null
                            ? 'Price on application'
                            : rand(l.priceZar!),
                        style: pw.TextStyle(
                          fontSize: 15,
                          color: _brand,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        pdfText(l.title),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.Text(
                        pdfText(
                          [
                            l.suburb,
                            l.address,
                            if (l.distanceM != null)
                              l.distanceM! < 1000
                                  ? '${(l.distanceM! / 10).round() * 10} m away'
                                  : '${(l.distanceM! / 1000).toStringAsFixed(1)} km away',
                          ].whereType<String>().join(' · '),
                        ),
                        style: const pw.TextStyle(fontSize: 9, color: _ink),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        [
                          if (l.bedrooms != null) '${l.bedrooms} bed',
                          if (l.bathrooms != null)
                            '${l.bathrooms! == l.bathrooms!.roundToDouble() ? l.bathrooms!.toInt() : l.bathrooms} bath',
                          if (l.parking != null) '${l.parking} parking',
                          if (l.floorM2 != null)
                            '${groupDigits(l.floorM2!)} m² floor',
                          if (l.erfM2 != null)
                            '${groupDigits(l.erfM2!)} m² erf',
                        ].join('  ·  '),
                        style: const pw.TextStyle(fontSize: 9, color: _ink),
                      ),
                      if (l.excerpt != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          pdfText(l.excerpt!),
                          maxLines: 3,
                          style: const pw.TextStyle(fontSize: 8, color: _muted),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.UrlLink(
                        destination: l.url,
                        child: pw.Text(
                          'View on Property24 (listing ${l.listingNumber})',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: _brand,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  // ---- valuation letter ------------------------------------------------------------

  pw.Widget _letter() {
    final signature = _img(pictures.signature);
    const body = pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 2);
    final bold = pw.TextStyle(
      fontSize: 10,
      color: _ink,
      fontWeight: pw.FontWeight.bold,
      lineSpacing: 2,
    );
    final attached = sections
        .where((s) => s != 'Valuation letter' && s != 'Your agent')
        .toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _letterhead(),
        pw.Text(_day.format(date), style: body),
        pw.SizedBox(height: 10),
        for (final line in report.displayAddress.split(', '))
          pw.Text(line, style: bold),
        pw.SizedBox(height: 12),
        pw.Text(
          pdfText(
            'Dear ${listing.greeting.isEmpty ? 'Owner' : listing.greeting},',
          ),
          style: bold,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'RE: MARKET-RELATED PROPERTY VALUATION: ${report.displayAddress.toUpperCase()} - ERF ${report.erf}',
          style: bold,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'As you requested, we have prepared a market-related valuation of your property. It is based on '
          'recent comparable sales in the area, the municipal valuation, current market conditions and the '
          'property itself.',
          style: body,
        ),
        pw.SizedBox(height: 8),
        pw.RichText(
          text: pw.TextSpan(
            style: body,
            children: [
              const pw.TextSpan(
                text:
                    'Having considered all of this, we estimate the current market value of your property at between ',
              ),
              pw.TextSpan(
                text: '${rand(valuation.low)} and ${rand(valuation.high)}',
                style: bold,
              ),
              const pw.TextSpan(text: ', and recommend a listing price of '),
              pw.TextSpan(text: rand(valuation.listingPrice), style: bold),
              const pw.TextSpan(text: ' to allow room for negotiation.'),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('The valuation takes into account:', style: body),
        for (final (title, text) in const [
          (
            'Location and demand',
            "the property's position relative to schools, shops, transport and amenities.",
          ),
          (
            'Comparable sales',
            'recent sales of similar homes nearby, which set the benchmark for price.',
          ),
          (
            'Condition and features',
            'the size, layout, improvements and overall condition of the home.',
          ),
          (
            'Market conditions',
            'interest rates and the economic conditions that shape buyer demand.',
          ),
        ])
          pw.Bullet(
            text: '$title: $text',
            style: body,
            bulletColor: _brand,
            bulletSize: 3,
          ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This is an estimate based on current market conditions and is not a formal appraisal for mortgage, '
          'legal or investment purposes; for those, we recommend a registered property valuer.',
          style: body,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Attached for your attention: ${attached.join('; ')}.',
          style: body,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'If you are considering selling, I would be glad to discuss a marketing plan to achieve the best '
          'possible price. Thank you for the opportunity to assist you.',
          style: body,
        ),
        pw.SizedBox(height: 14),
        pw.Text('Yours sincerely,', style: body),
        if (signature != null)
          pw.SizedBox(
            height: 40,
            width: 140,
            child: pw.Image(
              signature,
              fit: pw.BoxFit.contain,
              alignment: pw.Alignment.centerLeft,
            ),
          )
        else
          pw.SizedBox(height: 26),
        pw.Text(agent.name, style: bold),
        if (agent.jobTitle.isNotEmpty)
          pw.Text(agent.jobTitle.toUpperCase(), style: bold),
        pw.Text('REGISTERED WITH THE PPRA', style: bold),
        if (agent.ppraNumber.isNotEmpty)
          pw.Text('Reg no # ${agent.ppraNumber}', style: bold),
        if (agent.ffcNumber.isNotEmpty)
          pw.Text('FFC no # ${agent.ffcNumber}', style: bold),
        pw.Spacer(),
        _officeFooter(),
      ],
    );
  }

  // ---- costs ---------------------------------------------------------------------

  pw.Widget _costsPage() {
    const body = pw.TextStyle(fontSize: 9.5, color: _ink, lineSpacing: 1.5);
    final bold = pw.TextStyle(
      fontSize: 9.5,
      color: _ink,
      fontWeight: pw.FontWeight.bold,
    );
    final vat = costs.commissionIncludesVat ? ' incl. VAT' : '';
    String pct(double v) => '${v == v.roundToDouble() ? v.toInt() : v}%';
    final transfer = costs.transfer;
    final bond = costs.bond;
    pw.Widget line(String label, double amount, {bool strong = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text(label, style: strong ? bold : body)),
              pw.Text(rand(amount), style: strong ? bold : body),
            ],
          ),
        );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _letterhead(),
        pw.Center(
          child: pw.Text(
            'COSTS TO SELLER AND BUYER',
            style: pw.TextStyle(
              fontSize: 18,
              color: _brand,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'The seller (estimate; commission can be negotiated)',
          style: pw.TextStyle(
            fontSize: 11,
            color: _brand,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        for (final s in costs.seller) ...[
          line(
            'Sale price${s.price == costs.valuationPrice ? ' (market-related valuation)' : ' (listing price)'}',
            s.price,
            strong: true,
          ),
          line(
            'Net to seller if sold within ${costs.earlyMonths} months (commission ${pct(costs.commissionEarlyPercent)}$vat: ${rand(s.commissionEarly)})',
            s.netEarly,
          ),
          line(
            'Net to seller if sold after ${costs.earlyMonths} months (commission ${pct(costs.commissionLatePercent)}$vat: ${rand(s.commissionLate)})',
            s.netLate,
          ),
          pw.SizedBox(height: 6),
        ],
        pw.Text(
          'Net proceeds exclude bond cancellation, compliance certificates, rates, levies, capital gains tax and '
          'any other costs particular to the sale.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'The buyer (estimate)',
          style: pw.TextStyle(
            fontSize: 11,
            color: _brand,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        line(
          'Purchase price (market-related valuation)',
          costs.valuationPrice,
          strong: true,
        ),
        line('Transfer duty (SARS)', transfer.duty),
        line("Conveyancer's fee incl. VAT", transfer.attorneyFee),
        line('Deeds Office fee', transfer.deedsFee),
        line("Attorney's disbursements (typical)", transfer.extras),
        line('Transfer costs', transfer.total, strong: true),
        if (costs.bondAmount > 0) ...[
          pw.SizedBox(height: 4),
          line(
            'Bond registration on ${rand(costs.bondAmount)}: attorney incl. VAT',
            bond.attorneyFee,
          ),
          line(
            'Deeds Office fee and disbursements',
            bond.deedsFee + bond.extras,
          ),
          line('Bond costs', bond.total, strong: true),
        ],
        pw.SizedBox(height: 4),
        line('What the home costs the buyer', costs.buyerTotal, strong: true),
        pw.SizedBox(height: 12),
        pw.Text(
          'Home-loan repayment for the buyer (estimate)',
          style: pw.TextStyle(
            fontSize: 11,
            color: _brand,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        line(
          'Loan of ${rand(costs.bondAmount)} at ${pct(costs.interestRatePercent)} over ${costs.bondTermYears} years: per month',
          costs.monthlyRepaymentAmount,
          strong: true,
        ),
        line('Total repaid over the term', costs.totalRepayable),
        pw.SizedBox(height: 6),
        pw.Text(
          'Excludes the bank\'s initiation fee, utilities, insurance and maintenance. Transfer duty per SARS (1 April '
          '2026); conveyancing per the LSSA guideline (1 July 2026); Deeds Office fees from 1 April 2026.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.Spacer(),
        _officeFooter(),
      ],
    );
  }
}
