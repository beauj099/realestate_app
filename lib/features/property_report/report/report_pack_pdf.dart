import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/office_details.dart';
import '../data/models/area_details.dart';
import '../data/models/property_report.dart';
import 'costs_calculator.dart';
import 'pack_icons.dart';
import 'pack_listing.dart';
import 'valuation_report_pdf.dart';
import 'world_map.dart';

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

/// What the agent captured about the home: the cover's address and icons,
/// the "About the property" list and the letter.
class PackListing {
  /// "Piet & Mary Swanepoel": who the pack is prepared for.
  final String preparedFor;

  /// The owners' first names for the letter's greeting, e.g. "Piet & Mary".
  final String greeting;
  final List<String> portfolio;

  /// "10 Bosman Street" and "Strand, Cape Town", as the agent captured them.
  final String street;
  final String area;
  final PackFacts facts;

  const PackListing({
    this.preparedFor = '',
    this.greeting = '',
    this.portfolio = const [],
    this.street = '',
    this.area = '',
    this.facts = const PackFacts(),
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

  /// The cover's row of photos under the main one (up to three).
  final List<Uint8List> gallery;
  final Uint8List? agentPhoto;
  final Uint8List? signature;
  final Uint8List? logo;

  /// The office's logo variants (see `OfficeLogos`); each falls back to [logo].
  final Uint8List? logoMark;
  final Uint8List? logoWide;
  final Uint8List? logoWideOnBrand;

  /// Property24 listing photos by listing number.
  final Map<String, Uint8List> listingPhotos;
  final List<Uint8List> brochurePages;

  const PackImages({
    this.coverPhoto,
    this.secondPhoto,
    this.gallery = const [],
    this.agentPhoto,
    this.signature,
    this.logo,
    this.logoMark,
    this.logoWide,
    this.logoWideOnBrand,
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

  /// Behind the logo in the cover's top band: the agency's banner colour
  /// (the logo artwork's own background), as on the app's home screen.
  final Color? logoBackground;
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
    this.logoBackground,
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
  PdfColor get _logoBackground =>
      PdfColor.fromInt((logoBackground ?? brandColor).toARGB32());

  /// Whether the logo artwork sits on the brand colour itself (then it can go
  /// straight onto the agent card).
  bool get _logoOnBrand =>
      (logoBackground ?? brandColor).toARGB32() == brandColor.toARGB32();

  /// A logo for the brand colour: the office's own drawn for it, else the
  /// agency logo when its artwork already sits on that colour.
  pw.ImageProvider? get _logoForBrand =>
      _img(pictures.logoWideOnBrand) ??
      (_logoOnBrand ? _img(pictures.logo) : null);

  /// A wide logo for white paper.
  pw.ImageProvider? get _logoForWhite => _img(pictures.logoWide);

  /// The square mark, else the agency logo.
  pw.ImageProvider? get _logoMark =>
      _img(pictures.logoMark) ?? _img(pictures.logo);

  // The cover's serif, as on the agencies' own valuation covers.
  static final _serif = pw.Font.times();
  static final _serifBold = pw.Font.timesBold();

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
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => _agentPage(),
      ),
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

  static const _coverSide = 22.0;

  pw.Widget _cover() {
    final cover = _img(pictures.coverPhoto) ?? _img(_satellite);
    final gallery = [
      for (final g in pictures.gallery) ?_img(g),
    ].take(3).toList();
    final sold = report.lastSale;
    final street = listing.street.isNotEmpty
        ? listing.street
        : report.displayAddress.split(',').first;
    final area = listing.area.isNotEmpty ? listing.area : _title(report.suburb);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _coverLogoBand(),
        // The headline in a half frame, open at the bottom where the photo
        // band starts.
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(_coverSide, 18, _coverSide, 0),
          child: pw.Stack(
            alignment: pw.Alignment.topCenter,
            overflow: pw.Overflow.visible,
            children: [
              pw.Container(
                height: 58,
                margin: const pw.EdgeInsets.only(top: 14),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1.6),
                    left: pw.BorderSide(color: PdfColors.black, width: 1.6),
                    right: pw.BorderSide(color: PdfColors.black, width: 1.6),
                  ),
                ),
              ),
              pw.Container(
                color: PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                child: pw.Text(
                  'Market Related Property Valuation',
                  style: pw.TextStyle(
                    font: _serifBold,
                    fontSize: 26,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    pdfText(
                      '- $street, ${listing.area.isNotEmpty ? listing.area : _title(report.suburb)}  //  Erf ${report.erf} -',
                    ),
                    style: pw.TextStyle(
                      font: _serifBold,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // The main photo on the brand colour, with who it is prepared for on it.
        pw.Container(
          height: 330,
          color: _brand,
          padding: const pw.EdgeInsets.fromLTRB(_coverSide, 0, _coverSide, 0),
          child: pw.Stack(
            alignment: pw.Alignment.topCenter,
            children: [
              pw.Positioned.fill(
                child: cover == null
                    ? pw.Container(
                        color: _brand,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          pdfText(street),
                          style: pw.TextStyle(color: _onBrand, fontSize: 18),
                        ),
                      )
                    : pw.Image(cover, fit: pw.BoxFit.cover),
              ),
              if (listing.preparedFor.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(16, 5, 16, 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(14),
                    ),
                    child: pw.Text(
                      pdfText('Specially prepared for ${listing.preparedFor}.'),
                      style: pw.TextStyle(
                        font: _serif,
                        fontSize: 17,
                        letterSpacing: 0.4,
                        color: _brand,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (sold != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Center(
              child: pw.Text(
                pdfText(
                  '•  Last registered sale: ${_day.format(sold.date)}  •  '
                  'Price: ${rand(sold.priceZar)}  •',
                ),
                style: pw.TextStyle(
                  font: _serif,
                  fontSize: 10,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
        if (gallery.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(_coverSide, 8, _coverSide, 0),
            child: pw.Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.SizedBox(
                      height: 84,
                      child: i < gallery.length
                          ? pw.Image(gallery[i], fit: pw.BoxFit.cover)
                          : pw.SizedBox(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(_coverSide, 12, _coverSide, 0),
          child: _coverFacts(street, area),
        ),
        pw.Spacer(),
        _agentCard(),
      ],
    );
  }

  static String _title(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String get _brandHex =>
      (brandColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

  /// The agency's logo filling the top band, on the logo's own background.
  pw.Widget _coverLogoBand() {
    final logo = _logoForBrand != null && _logoOnBrand
        ? _logoForBrand
        : _img(pictures.logo);
    return pw.Container(
      height: 64,
      color: _logoBackground,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _coverSide,
        vertical: 9,
      ),
      alignment: pw.Alignment.centerLeft,
      child: logo == null
          ? pw.Text(
              agent.agencyName,
              style: pw.TextStyle(
                color: _logoOnBrand ? _onBrand : _brand,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            )
          : pw.Image(
              logo,
              fit: pw.BoxFit.contain,
              alignment: pw.Alignment.centerLeft,
            ),
    );
  }

  /// Street and area, then the home in icons and numbers.
  pw.Widget _coverFacts(String street, String area) {
    final f = listing.facts;
    String n(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
    final items = <(String, String, String)>[
      if (f.bedrooms > 0) ('bedrooms', n(f.bedrooms), 'Bedrooms'),
      if (f.bathrooms > 0) ('bathrooms', n(f.bathrooms), 'Bathrooms'),
      if (f.garages > 0) ('garages', n(f.garages), 'Garages'),
      if (f.parking > 0) ('parking', n(f.parking), 'Parking'),
      if ((f.floorM2 ?? report.dwellingExtentM2) case final floor?
          when floor > 0)
        ('floor', '${groupDigits(floor)} m²', 'Floor size'),
      if ((f.erfM2 ?? report.extentM2) case final erf? when erf > 0)
        ('erf', '${groupDigits(erf)} m²', 'Erf size'),
      if (f.yearBuilt != null) ('built', '${f.yearBuilt}', 'Built'),
      // Features without a number: the icon and its name.
      for (final (icon, name) in f.extras) (icon, name, ''),
    ];
    const perRow = 4;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          pdfText(street),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            if (packIcon('place', _brandHex) case final svg?)
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 3),
                child: pw.SvgImage(svg: svg, width: 11, height: 11),
              ),
            pw.Text(
              pdfText(
                [
                  area,
                  if (readableZoning(
                        report.zoningCode,
                        report.zoningDescription,
                      )
                      case final zoning?)
                    'Zoned $zoning',
                ].join('   ·   '),
              ),
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        for (var r = 0; r < items.length; r += perRow)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                for (var i = r; i < r + perRow; i++)
                  pw.Expanded(
                    child: i >= items.length
                        ? pw.SizedBox()
                        : _fact(items[i].$1, items[i].$2, items[i].$3),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _fact(String icon, String value, String label) => pw.Row(
    children: [
      if (packIcon(icon, _brandHex) case final svg?)
        pw.SvgImage(svg: svg, width: 20, height: 20),
      pw.SizedBox(width: 7),
      pw.Expanded(
        child: label.isEmpty
            // A feature without a number: its name, as on the portals.
            ? pw.Text(
                pdfText(value),
                style: const pw.TextStyle(fontSize: 10, color: _ink),
              )
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    pdfText(value),
                    style: pw.TextStyle(
                      fontSize: 12.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.Text(
                    label,
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                  ),
                ],
              ),
      ),
    ],
  );

  Uint8List? get _satellite {
    for (final i in report.printableImagery) {
      if (images[i.url] case final bytes?) return bytes;
    }
    return null;
  }

  /// The listing's own portfolio first, then what the records add.
  List<String> get _portfolio => [
    if (readableZoning(report.zoningCode, report.zoningDescription)
        case final zoning?)
      'Zoned: $zoning',
    if (report.extentM2 != null)
      'Erf size: ${groupDigits(report.extentM2!)} m²',
    ...listing.portfolio,
  ];

  /// The agent across the foot of the cover, on the brand colour, with the
  /// agency's logo in the right corner.
  pw.Widget _agentCard() {
    final photo = _img(pictures.agentPhoto);
    final onBrandLogo = _logoForBrand;
    final logo = onBrandLogo ?? _img(pictures.logo);
    final onBrandHex = (onBrandColor.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    pw.Widget contact(String icon, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Row(
        children: [
          if (packIcon(icon, onBrandHex) case final svg?)
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 7),
              child: pw.SvgImage(svg: svg, width: 10, height: 10),
            ),
          pw.Text(value, style: pw.TextStyle(color: _onBrand, fontSize: 9.5)),
        ],
      ),
    );
    return pw.Container(
      height: 108,
      color: _brand,
      padding: const pw.EdgeInsets.fromLTRB(_coverSide, 10, _coverSide, 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (photo != null)
            pw.Container(
              width: 76,
              height: 86,
              margin: const pw.EdgeInsets.only(right: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.white, width: 2),
              ),
              child: pw.Image(photo, fit: pw.BoxFit.cover),
            ),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  agent.name,
                  style: pw.TextStyle(
                    color: _onBrand,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (agent.jobTitle.isNotEmpty)
                  pw.Text(
                    agent.jobTitle,
                    style: pw.TextStyle(color: _onBrand, fontSize: 9.5),
                  ),
                pw.SizedBox(height: 6),
                if (agent.mobile.isNotEmpty) contact('phone', agent.mobile),
                if (agent.email.isNotEmpty) contact('email', agent.email),
                if (agent.website.isNotEmpty) contact('website', agent.website),
              ],
            ),
          ),
          if (logo != null)
            onBrandLogo != null
                ? pw.SizedBox(
                    width: 170,
                    height: 56,
                    child: pw.Image(
                      logo,
                      fit: pw.BoxFit.contain,
                      alignment: pw.Alignment.bottomRight,
                    ),
                  )
                : pw.Container(
                    width: 150,
                    height: 56,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _logoBackground,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
        ],
      ),
    );
  }

  // ---- contents and letterhead ---------------------------------------------

  pw.Widget _letterhead() {
    final logo = _logoForWhite ?? _img(pictures.logo);
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
      if (_portfolio.isNotEmpty) ...[
        pw.SizedBox(height: 26),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _rule),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'About the property',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _brand,
                ),
              ),
              pw.SizedBox(height: 6),
              for (final line in _portfolio)
                pw.Bullet(
                  text: pdfText(line),
                  style: const pw.TextStyle(fontSize: 9.5, color: _ink),
                  margin: const pw.EdgeInsets.only(bottom: 3),
                  bulletColor: _brand,
                  bulletSize: 3,
                ),
            ],
          ),
        ),
      ],
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

  /// The brand colour mixed into white: [amount] 0 is white, 1 the brand.
  PdfColor _tint(double amount) => PdfColor(
    1 - (1 - _brand.red) * amount,
    1 - (1 - _brand.green) * amount,
    1 - (1 - _brand.blue) * amount,
  );

  static const _pageSide = 40.0;

  /// "Your agent": a faint world map behind the heading, the photo with the
  /// qualifications under it, the agent's own words beside it with their
  /// contact details in a banner, and the agency at the foot.
  pw.Widget _agentPage() {
    final photo = _img(pictures.agentPhoto);
    final logo = _logoMark;
    return pw.Stack(
      children: [
        pw.Positioned(
          left: -10,
          top: 95,
          child: pw.SvgImage(svg: worldMapSvg('EDEDED'), width: 620),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // The agency's mark, top right.
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(_pageSide, 26, 28, 0),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  if (agent.office.slogan.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 12),
                      child: pw.Text(
                        pdfText(agent.office.slogan),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: _ink,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  pw.Container(
                    height: 44,
                    width: logo == null ? null : 44,
                    // The office's own mark is drawn as it is; the agency
                    // logo sits on its banner colour.
                    padding: pictures.logoMark != null
                        ? pw.EdgeInsets.zero
                        : const pw.EdgeInsets.all(4),
                    color: pictures.logoMark != null ? null : _logoBackground,
                    child: logo == null
                        ? pw.Center(
                            child: pw.Text(
                              agent.agencyName,
                              style: pw.TextStyle(
                                color: _onBrand,
                                fontSize: 10,
                              ),
                            ),
                          )
                        : pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(
                _pageSide,
                14,
                _pageSide,
                0,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'YOUR',
                    style: const pw.TextStyle(fontSize: 21, color: _ink),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      style: const pw.TextStyle(fontSize: 30, color: _ink),
                      children: [
                        // *word* is printed in the brand colour.
                        for (final (i, part) in pdfText(
                          agent.office.headline.isNotEmpty
                              ? agent.office.headline
                              : OfficeDetails.defaultHeadline,
                        ).split('*').indexed)
                          pw.TextSpan(
                            text: part,
                            style: i.isOdd ? pw.TextStyle(color: _brand) : null,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: _pageSide),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Photo, and the qualifications under it.
                  pw.SizedBox(
                    width: 170,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (photo != null)
                          pw.Container(
                            width: 170,
                            height: 205,
                            child: pw.Image(photo, fit: pw.BoxFit.cover),
                          ),
                        if (agent.qualifications.isNotEmpty) ...[
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'Qualifications & Registrations',
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          for (final q in agent.qualifications)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(
                                    width: 5,
                                    height: 5,
                                    margin: const pw.EdgeInsets.only(
                                      top: 3.5,
                                      right: 7,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: _brand,
                                      shape: pw.BoxShape.circle,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      pdfText(q),
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  // Name, their own words, and how to reach them.
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          agent.name,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                        if (agent.jobTitle.isNotEmpty)
                          pw.Text(
                            agent.jobTitle,
                            style: const pw.TextStyle(
                              fontSize: 14,
                              color: _ink,
                            ),
                          ),
                        pw.Container(
                          width: 40,
                          height: 2.5,
                          margin: const pw.EdgeInsets.symmetric(vertical: 12),
                          color: _brand,
                        ),
                        if (agent.bio.isNotEmpty)
                          pw.Text(
                            pdfText(agent.bio),
                            style: const pw.TextStyle(
                              fontSize: 10.5,
                              color: _ink,
                              lineSpacing: 3.5,
                            ),
                          ),
                        pw.SizedBox(height: 18),
                        _contactBanner(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
              color: _brand,
              padding: const pw.EdgeInsets.symmetric(vertical: 9),
              child: pw.Center(
                child: pw.Text(
                  'registered professional property practitioner',
                  style: pw.TextStyle(
                    color: _onBrand,
                    fontSize: 10.5,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
            _agencyFooterBlock(),
          ],
        ),
      ],
    );
  }

  /// Phone, email and website in a banner on a tint of the brand colour.
  pw.Widget _contactBanner() {
    final rows = [
      if (agent.mobile.isNotEmpty) ('phone', agent.mobile),
      if (agent.email.isNotEmpty) ('email', agent.email),
      if (agent.website.isNotEmpty) ('website', agent.website),
    ];
    final registrations = [
      if (agent.ppraNumber.isNotEmpty) 'PPRA reg. no. ${agent.ppraNumber}',
      if (agent.ffcNumber.isNotEmpty) 'FFC no. ${agent.ffcNumber}',
    ];
    if (rows.isEmpty && registrations.isEmpty) return pw.SizedBox();
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: pw.BoxDecoration(
        color: _tint(0.07),
        border: pw.Border(left: pw.BorderSide(color: _brand, width: 4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GET IN TOUCH',
            style: pw.TextStyle(
              fontSize: 8.5,
              letterSpacing: 2,
              fontWeight: pw.FontWeight.bold,
              color: _brand,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final (icon, value) in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Row(
                children: [
                  if (packIcon(icon, _brandHex) case final svg?)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 9),
                      child: pw.SvgImage(svg: svg, width: 14, height: 14),
                    ),
                  pw.Text(
                    value,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: _ink,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          if (registrations.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              registrations.join('     '),
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
          ],
        ],
      ),
    );
  }

  /// The agency at the foot of the page: its logo, a rule, and the office's
  /// name, address and contacts, with the legal line under them.
  pw.Widget _agencyFooterBlock() {
    final white = _logoForWhite;
    final logo = white ?? _img(pictures.logo);
    final office = agent.office;
    final contacts = [
      if (office.phone.isNotEmpty) 'Tel ${office.phone}',
      if (office.email.isNotEmpty) office.email,
    ];
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(_pageSide, 16, _pageSide, 22),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 170,
                height: 64,
                padding: const pw.EdgeInsets.all(6),
                color: logo == null || white != null ? null : _logoBackground,
                alignment: pw.Alignment.center,
                child: logo == null
                    ? pw.Text(
                        agent.agencyName,
                        style: pw.TextStyle(
                          color: _brand,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      )
                    : pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.Container(
                width: 2,
                height: 64,
                margin: const pw.EdgeInsets.symmetric(horizontal: 18),
                color: _ink,
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      pdfText(
                        office.name.isNotEmpty ? office.name : agent.agencyName,
                      ),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    if (office.address.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text(
                          pdfText(office.address),
                          style: const pw.TextStyle(fontSize: 10, color: _ink),
                        ),
                      ),
                    if (contacts.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          contacts.join('   |   '),
                          style: const pw.TextStyle(fontSize: 10, color: _ink),
                        ),
                      ),
                    if (office.website.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          office.website,
                          style: pw.TextStyle(fontSize: 10, color: _brand),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (office.footer.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              pdfText(office.footer),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5, color: _muted),
            ),
          ],
        ],
      ),
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
