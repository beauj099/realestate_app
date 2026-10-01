import 'dart:math' as math;
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
import 'portrait_crop.dart';
import 'pack_listing.dart';
import 'valuation_report_pdf.dart';
import 'world_map.dart';
import 'report_fonts.dart';

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

  /// When the owners bought and for how much, as they told the agent.
  final ({DateTime date, double priceZar})? ownersPurchase;

  /// The agent's walk-through: the rooms as captured in the listing.
  final PackInspection? inspection;

  /// Monthly rent of each let flatlet, for the letter: income a buyer can
  /// count on.
  final List<double> flatletRents;

  const PackListing({
    this.preparedFor = '',
    this.greeting = '',
    this.portfolio = const [],
    this.street = '',
    this.area = '',
    this.facts = const PackFacts(),
    this.ownersPurchase,
    this.inspection,
    this.flatletRents = const [],
  });
}

/// The agent's inspection of the home, from the rooms captured in the
/// listing: proof the agent walked it, which no data source can give.
class PackInspection {
  final List<PackRoom> rooms;

  /// The overall house score, 0-100.
  final double? houseScore;

  /// "Built in 1985", "620 m² under roof", "2 garages"…: the home as a whole.
  final List<String> building;

  /// Outside: pool, garden, borehole…
  final List<String> outside;

  const PackInspection({
    this.rooms = const [],
    this.houseScore,
    this.building = const [],
    this.outside = const [],
  });

  bool get isEmpty => rooms.isEmpty;
}

class PackRoom {
  final String name;

  /// "Very good", on the app's six-band scale; empty when not rated.
  final String condition;

  /// 1 (to be remodeled) to 6 (excellent); null when not rated.
  final int? conditionLevel;

  /// The agent's 0-10 score; null when not scored.
  final double? score;
  final List<String> features;
  final String notes;

  const PackRoom({
    required this.name,
    this.condition = '',
    this.conditionLevel,
    this.score,
    this.features = const [],
    this.notes = '',
  });
}

/// The agent's conclusions, entered before the pack is made.
class PackValuation {
  final double low;
  final double high;
  final double listingPrice;

  /// Why the agent's range differs from the recorded sales' (the pool, the
  /// flatlet, the condition…); the letter says it when the two differ.
  final String adjustmentReason;
  const PackValuation({
    required this.low,
    required this.high,
    required this.listingPrice,
    this.adjustmentReason = '',
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

  /// Property24 listing photos by listing number: the main one, and up to
  /// three more for the row under it.
  final Map<String, Uint8List> listingPhotos;
  final Map<String, List<Uint8List>> listingMorePhotos;
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
    this.listingMorePhotos = const {},
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
  final String? areaMapSvg;
  final String? blockMapSvg;
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
    this.areaMapSvg,
    this.blockMapSvg,
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

  String get _brandInkHex =>
      (_brandInk.toInt() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

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

  String get fileName =>
      'Valuation - ${report.displayAddress.replaceAll(',', '')}.pdf';

  static pw.ImageProvider? _img(Uint8List? bytes) =>
      ValuationReportPdf.isEmbeddableImage(bytes)
      ? pw.MemoryImage(bytes!)
      : null;

  late final ValuationReportPdf _analysis = ValuationReportPdf(
    report: report,
    sitePlanSvg: sitePlanSvg,
    areaMapSvg: areaMapSvg,
    blockMapSvg: blockMapSvg,
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
    ownersPurchase: listing.ownersPurchase,
    logo: pictures.logo,
    showAuthor: false,
    showSources: false,
    date: date,
  );

  bool get _hasArea => area != null && !area!.isEmpty;
  bool get _hasMarket => forSale?.listings.isNotEmpty ?? false;

  /// The sections, in order, for the contents page and the letter.
  bool get _hasInspection => !(listing.inspection?.isEmpty ?? true);

  List<String> get sections => [
    'Your agent',
    if (_hasInspection) 'Property inspection',
    'Market valuation analysis',
    if (_hasArea) 'Area details',
    if (_hasMarket) 'Homes on the market like yours',
    'Valuation letter',
    'Costs to seller and buyer',
    if (pictures.brochurePages.isNotEmpty) 'About ${agent.agencyName}',
  ];

  /// Built twice: the first pass finds the page each section starts on, the
  /// second writes those numbers into the contents (whose layout does not
  /// depend on them).
  Future<Uint8List> build() async {
    final found = <String, int>{};
    await (await _document(found, const {})).save();
    return (await _document(<String, int>{}, found)).save();
  }

  Future<pw.Document> _document(
    Map<String, int> found,
    Map<String, int> numbers,
  ) async {
    // Records the first page each section appears on.
    void at(String section, pw.Context context) =>
        found.putIfAbsent(section, () => context.pageNumber);
    pw.Widget Function(pw.Context) header(String section) => (context) {
      at(section, context);
      return _analysis.header(context);
    };
    if (_img(pictures.signature) == null && agent.name.trim().isNotEmpty) {
      _signatureFont = await reportSignatureFont();
    }
    if (agent.office.headingFont == 'serif') {
      final (regular, bold) = await reportSerif();
      _headingFont = regular;
      _headingBold = bold;
    }
    final doc = pw.Document(
      title: 'Valuation - ${report.displayAddress}',
      author: agent.name.isEmpty ? null : agent.name,
      creator: 'RealWorth',
      theme: await reportTheme(),
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
      pw.Page(
        pageFormat: format,
        margin: _margin,
        build: (_) => _contents(numbers),
      ),
    );
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          at('Your agent', context);
          return _agentPage();
        },
      ),
    );
    if (_hasInspection) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: _margin,
          header: header('Property inspection'),
          footer: _analysis.footer,
          build: (_) => _inspectionPage(listing.inspection!),
        ),
      );
    }
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: _margin,
        header: header('Market valuation analysis'),
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
          header: header('Area details'),
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
          header: header('Homes on the market like yours'),
          footer: _analysis.footer,
          build: (_) => _marketPage(forSale!),
        ),
      );
    }
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: _margin,
        build: (context) {
          at('Valuation letter', context);
          return _letter();
        },
      ),
    );
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: _margin,
        build: (context) {
          at('Costs to seller and buyer', context);
          return _costsPage();
        },
      ),
    );
    for (final page in pictures.brochurePages) {
      final image = _img(page);
      if (image == null) continue;
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            at('About ${agent.agencyName}', context);
            return pw.Image(image, fit: pw.BoxFit.contain);
          },
        ),
      );
    }
    return doc;
  }

  // ---- cover ---------------------------------------------------------------

  static const _coverSide = 22.0;

  pw.Widget _cover() {
    final cover = _img(pictures.coverPhoto) ?? _img(_satellite);
    final gallery = [
      for (final g in pictures.gallery) ?_img(g),
    ].take(3).toList();
    final street = listing.street.isNotEmpty
        ? listing.street
        : report.displayAddress.split(',').first;
    final area = listing.area.isNotEmpty ? listing.area : _title(report.suburb);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _coverLogoBand(),
        // One thin frame in the agency colour: its top line runs out from the
        // headline to the page's sides and down both sides of the photos,
        // open at the bottom.
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(6, 16, 6, 0),
          child: pw.Stack(
            alignment: pw.Alignment.topCenter,
            overflow: pw.Overflow.visible,
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 16),
                padding: const pw.EdgeInsets.fromLTRB(6, 26, 6, 0),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: _brand, width: 1.6),
                    left: pw.BorderSide(color: _brand, width: 1.6),
                    right: pw.BorderSide(color: _brand, width: 1.6),
                  ),
                ),
                // A little shorter when the note line takes room below.
                child: _coverPhotos(
                  cover,
                  gallery,
                  street,
                  mainHeight: _coverNote == null ? 318 : 300,
                ),
              ),
              pw.Container(
                color: PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                child: pw.Text(
                  'Market Related Property Valuation',
                  style: _h(
                    pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      // A serif sets smaller: a little larger to match.
                      fontSize: _headingFont == null ? 26 : 29,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_coverNote case final note?)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Center(
              child: pw.Text(
                pdfText(note),
                style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
              ),
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

  /// The main photo and the three under it, black lines between them (the
  /// black background showing through small gaps, since a photo is drawn
  /// over its own border).
  pw.Widget _coverPhotos(
    pw.ImageProvider? cover,
    List<pw.ImageProvider> gallery,
    String street, {
    double mainHeight = 318,
  }) => pw.Container(
    color: PdfColors.black,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(
          height: mainHeight,
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
                      style: _h(
                        pw.TextStyle(
                          fontSize: _headingFont == null ? 17 : 19,
                          letterSpacing: 0.4,
                          color: _brandInk,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (gallery.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) pw.SizedBox(width: 2),
                pw.Expanded(
                  child: pw.SizedBox(
                    height: 90,
                    child: i < gallery.length
                        ? pw.Image(gallery[i], fit: pw.BoxFit.cover)
                        : pw.SizedBox(),
                  ),
                ),
              ],
            ],
          ),
        ],
        pw.SizedBox(height: 2),
      ],
    ),
  );

  /// Under the cover photos: the last registered sale (or, failing that,
  /// the owners' own purchase) and the agent's inspection. Null if neither.
  String? get _coverNote {
    final sold = report.lastSale;
    final bought = listing.ownersPurchase;
    final seen = listing.inspection;
    final first = agent.name.split(' ').first;
    final parts = [
      if (sold != null)
        'Last registered sale: ${DateFormat('MMM yyyy').format(sold.date)} · ${rand(sold.priceZar)}'
      else if (bought != null)
        'Bought: ${DateFormat('MMM yyyy').format(bought.date)} · ${rand(bought.priceZar)}',
      if (seen != null && !seen.isEmpty)
        'Inspected by $first: ${seen.rooms.length} rooms'
            '${seen.houseScore == null ? '' : ', overall ${seen.houseScore!.round()}%'}',
    ];
    return parts.isEmpty ? null : parts.join('   •   ');
  }

  static String _title(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// The agency's logo filling the top band, on the logo's own background.
  pw.Widget _coverLogoBand() {
    final logo = _logoForBrand != null && _logoOnBrand
        ? _logoForBrand
        : _img(pictures.logo);
    return pw.Container(
      height: 78,
      color: _logoBackground,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _coverSide,
        vertical: 14,
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
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
          ),
          // The date: a valuation is a snapshot in time. Right, and in the
          // middle of the band's height.
          pw.Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: pw.Center(
              child: pw.Text(
                _day.format(date),
                style: pw.TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.6,
                  color: _logoOnBrand ? _onBrand : _ink,
                ),
              ),
            ),
          ),
        ],
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
      // The registered extent first, as on the analysis page.
      if ((report.extentM2 ?? f.erfM2) case final erf? when erf > 0)
        ('erf', '${groupDigits(erf)} m²', 'Erf size'),
      if (f.yearBuilt != null) ('built', '${f.yearBuilt}', 'Built'),
      // Features without a number: the icon and its name.
      for (final (icon, name) in f.extras) (icon, name, ''),
    ];
    const perRow = 4;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // The address on the left; the erf and how it is zoned on the right.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    pdfText(street),
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      if (packIcon('place', _brandInkHex) case final svg?)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 3),
                          child: pw.SvgImage(svg: svg, width: 11, height: 11),
                        ),
                      pw.Text(
                        pdfText(area),
                        style: const pw.TextStyle(
                          fontSize: 11.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Erf ${report.erf}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (readableZoning(report.zoningCode, report.zoningDescription)
                    case final zoning?)
                  pw.Text(
                    pdfText('Zoned $zoning'),
                    style: const pw.TextStyle(fontSize: 10, color: _muted),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        for (var r = 0; r < items.length; r += perRow)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 13),
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
      if (packIcon(icon, _brandInkHex) case final svg?)
        pw.SvgImage(svg: svg, width: 20, height: 20),
      pw.SizedBox(width: 7),
      pw.Expanded(
        child: label.isEmpty
            // A feature without a number: its name, as on the portals.
            ? pw.Text(
                pdfText(value),
                style: const pw.TextStyle(fontSize: 11, color: _ink),
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
                    style: const pw.TextStyle(fontSize: 8.5, color: _muted),
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

  /// The agent across the foot of the cover, on the brand colour, with the
  /// agency's logo in the right corner.
  pw.Widget _agentCard() {
    final photo = _img(pictures.agentPhoto);
    // Used by the logo in the corner, now commented out below:
    // final onBrandLogo = _logoForBrand;
    // final logo = onBrandLogo ?? _img(pictures.logo);
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
          pw.Text(value, style: pw.TextStyle(color: _onBrand, fontSize: 10.5)),
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
                    style: pw.TextStyle(color: _onBrand, fontSize: 10.5),
                  ),
                pw.SizedBox(height: 6),
                if (agent.mobile.isNotEmpty) contact('phone', agent.mobile),
                if (agent.email.isNotEmpty) contact('email', agent.email),
                if (agent.website.isNotEmpty) contact('website', agent.website),
              ],
            ),
          ),
          // The agency's slogan in the corner. (Was the agency's logo, which
          // repeated the band at the top of the page; kept below in case it
          // comes back.)
          if (agent.office.slogan.isNotEmpty)
            pw.SizedBox(
              width: 170,
              child: pw.Text(
                pdfText(agent.office.slogan),
                textAlign: pw.TextAlign.right,
                style: _h(
                  pw.TextStyle(fontSize: 14, color: _onBrand, lineSpacing: 2),
                ),
              ),
            ),
          // if (logo != null)
          //   onBrandLogo != null
          //       ? pw.SizedBox(
          //           width: 170,
          //           height: 56,
          //           child: pw.Image(
          //             logo,
          //             fit: pw.BoxFit.contain,
          //             alignment: pw.Alignment.bottomRight,
          //           ),
          //         )
          //       : pw.Container(
          //           width: 150,
          //           height: 56,
          //           padding: const pw.EdgeInsets.all(6),
          //           decoration: pw.BoxDecoration(
          //             color: _logoBackground,
          //             borderRadius: pw.BorderRadius.circular(6),
          //           ),
          //           child: pw.Image(logo, fit: pw.BoxFit.contain),
          //         ),
        ],
      ),
    );
  }

  // ---- contents and letterhead ---------------------------------------------

  /// The logo over a rule. The office's address and numbers are on the agent
  /// page only, not repeated at the top of every page.
  pw.Widget _letterhead() {
    final logo = _logoForWhite ?? _img(pictures.logo);
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 18),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 1.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          logo == null
              ? pw.Text(
                  agent.agencyName,
                  style: pw.TextStyle(
                    color: _brandInk,
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
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ),
        );

  /// The contents, with each section's first page from [numbers] (empty on
  /// the first pass).
  pw.Widget _contents(Map<String, int> numbers) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _letterhead(),
      pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              'MARKET RELATED VALUATION REPORT',
              style: pw.TextStyle(fontSize: 20, color: _brandInk),
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
                  style: pw.TextStyle(color: _brandInk, fontSize: 12),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  s,
                  style: pw.TextStyle(color: _ink, fontSize: 13),
                ),
              ),
              pw.Text(
                numbers[s] == null ? '' : 'Page ${numbers[s]}',
                style: pw.TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      pw.Spacer(),
      _officeFooter(),
    ],
  );

  /// The agency's heading font, when it has one (see
  /// [OfficeDetails.headingFont]); null keeps the body font.
  pw.Font? _headingFont, _headingBold;

  /// The default signature's handwriting face, loaded when the agent has no
  /// signature image.
  pw.Font? _signatureFont;

  /// [style] in the agency's heading font, when it has one.
  pw.TextStyle _h(pw.TextStyle style) => _headingFont == null
      ? style
      : style.copyWith(
          font: _headingFont,
          fontNormal: _headingFont,
          fontBold: _headingBold,
        );

  pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Text(
      text,
      style: _h(
        pw.TextStyle(
          fontSize: 18,
          color: _brandInk,
          fontWeight: pw.FontWeight.bold,
        ),
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
                        style: _h(
                          const pw.TextStyle(
                            fontSize: 12,
                            color: _ink,
                            letterSpacing: 0.3,
                          ),
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
                                fontSize: 11,
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
                    style: _h(const pw.TextStyle(fontSize: 21, color: _ink)),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      style: _h(const pw.TextStyle(fontSize: 30, color: _ink)),
                      children: [
                        // *word* is printed in the brand colour.
                        for (final (i, part) in pdfText(
                          agent.office.headline.isNotEmpty
                              ? agent.office.headline
                              : OfficeDetails.defaultHeadline,
                        ).split('*').indexed)
                          pw.TextSpan(
                            text: part,
                            style: i.isOdd
                                ? pw.TextStyle(color: _brandInk)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 36),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(
                  _pageSide,
                  0,
                  _pageSide,
                  16,
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Photo, and the qualifications under it.
                    pw.SizedBox(
                      width: 170,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // A little below the name, as on the agencies' own pages.
                          pw.SizedBox(height: 20),
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
                                fontSize: 11.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            for (final q in agent.qualifications)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
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
                                          fontSize: 11,
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
                                fontSize: 11.5,
                                color: _ink,
                                lineSpacing: 3.5,
                              ),
                            ),
                          // How to reach them sits at the foot of the column,
                          // just above the banner.
                          pw.Spacer(),
                          pw.SizedBox(height: 14),
                          _contactBanner(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 20),
              color: _tint(0.82),
              padding: const pw.EdgeInsets.symmetric(vertical: 9),
              child: pw.Center(
                child: pw.Text(
                  'registered property practitioner in real estate',
                  style: pw.TextStyle(
                    color: _onBrand,
                    fontSize: 11.5,
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
      if (agent.ppraNumber.isNotEmpty) ('PPRA reg. no.', agent.ppraNumber),
      if (agent.ffcNumber.isNotEmpty) ('FFC no.', agent.ffcNumber),
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
              fontSize: 9.5,
              letterSpacing: 2,
              fontWeight: pw.FontWeight.bold,
              color: _brandInk,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final (icon, value) in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Row(
                children: [
                  if (packIcon(icon, _brandInkHex) case final svg?)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 9),
                      child: pw.SvgImage(svg: svg, width: 14, height: 14),
                    ),
                  pw.Text(
                    value,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: _ink,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          if (registrations.isNotEmpty) ...[
            pw.Container(
              height: 0.8,
              margin: const pw.EdgeInsets.only(top: 10, bottom: 8),
              color: _tint(0.25),
            ),
            pw.Wrap(
              spacing: 22,
              runSpacing: 4,
              children: [
                for (final (label, number) in registrations)
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '$label  ',
                          style: const pw.TextStyle(
                            fontSize: 10.5,
                            color: _muted,
                          ),
                        ),
                        pw.TextSpan(
                          text: number,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
                          color: _brandInk,
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
                          style: const pw.TextStyle(fontSize: 11, color: _ink),
                        ),
                      ),
                    if (contacts.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          contacts.join('   |   '),
                          style: const pw.TextStyle(fontSize: 11, color: _ink),
                        ),
                      ),
                    if (office.website.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          office.website,
                          style: pw.TextStyle(fontSize: 11, color: _brandInk),
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
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
          ],
        ],
      ),
    );
  }

  // ---- area details -----------------------------------------------------------

  List<pw.Widget> _areaPage(AreaDetails a) {
    final p = a.population;
    final c = a.crime;
    final w = a.climate;
    final income = a.income;
    return [
      _sectionTitle('Area details'),
      if (p != null || income != null) ...[
        _areaHeading(
          'people',
          'The neighbourhood',
          // Census area names can differ from the suburb the listing uses.
          p?.subPlace == null
              ? null
              : 'Census area: ${[p!.subPlace, p.mainPlace].whereType<String>().join(', ')}',
        ),
        _tiles([
          if (p?.estimatedPopulation ?? p?.population case final people?)
            (
              'people',
              groupDigits(people),
              p!.estimatedPopulation != null
                  ? 'People (${p.estimateYear} estimate)'
                  : 'People (${p.year})',
            ),
          if (p?.households case final households?)
            ('homes', groupDigits(households), 'Households (${p!.year})'),
          if (p?.peoplePerKm2 case final density?)
            ('area', groupDigits(density), 'People per km²'),
          if (income != null)
            ('income', income.medianBand, 'Middle household income'),
        ]),
        if (income != null)
          _note('Household income is for the whole ${income.municipality}.'),
      ],
      if (a.nearby.isNotEmpty) ..._nearbyBlock(a.nearby),
      if (c != null) ..._crimeBlock(c),
      if (a.water != null) ..._waterBlock(a.water!),
      if (a.loadShedding case final shedding? when shedding.years.isNotEmpty)
        ..._loadSheddingBlock(shedding),
      if (w != null) ..._climateBlock(w),
    ];
  }

  /// The colour each group of places is drawn in (as on the block map).
  static const _placeColours = {
    'schools': PdfColor.fromInt(0xFF7B4FD6),
    'shopping': PdfColor.fromInt(0xFFE08A1E),
    'health': PdfColor.fromInt(0xFFD93A4A),
    'parks': PdfColor.fromInt(0xFF2E9E5B),
    'beach': PdfColor.fromInt(0xFF1E9BD7),
    'transport': PdfColor.fromInt(0xFF4A5563),
    'police': PdfColor.fromInt(0xFF1F3A93),
  };

  static String _distance(double m) => m < 1000
      ? '${(m / 10).round() * 10} m'
      : '${(m / 1000).toStringAsFixed(1)} km';

  /// What is nearby: two columns of groups, each place with its distance.
  List<pw.Widget> _nearbyBlock(List<NearbyGroup> groups) {
    pw.Widget group(NearbyGroup g) {
      final colour = _placeColours[g.key] ?? _brand;
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF5F6F8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 20,
                  height: 20,
                  padding: const pw.EdgeInsets.all(3.5),
                  decoration: pw.BoxDecoration(
                    color: colour,
                    shape: pw.BoxShape.circle,
                  ),
                  child: switch (packIcon(g.key, 'FFFFFF')) {
                    final svg? => pw.SvgImage(svg: svg),
                    _ => null,
                  },
                ),
                pw.SizedBox(width: 7),
                pw.Text(
                  pdfText(g.title),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            for (final place in g.places)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2.5),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        pdfText(place.name),
                        style: const pw.TextStyle(fontSize: 9.5, color: _ink),
                        maxLines: 1,
                      ),
                    ),
                    pw.Text(
                      _distance(place.distanceM),
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: colour,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final left = <NearbyGroup>[];
    final right = <NearbyGroup>[];
    for (final (i, g) in groups.indexed) {
      (i.isEven ? left : right).add(g);
    }
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _areaHeading(
              'area',
              'What is nearby',
              'Distances in a straight line from the property',
            ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(children: [for (final g in left) group(g)]),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(children: [for (final g in right) group(g)]),
                ),
              ],
            ),
          ],
        ),
      ),
      _note('Straight-line distances, not by road.'),
    ];
  }

  /// Past scheduled load-shedding: hours per year as bars, when it usually
  /// fell, and what the figures are (scheduled, not measured).
  List<pw.Widget> _loadSheddingBlock(LoadSheddingHistory h) {
    final most = h.years.fold<double>(1, (m, y) => y.hours > m ? y.hours : m);
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _areaHeading('backup', 'Load-shedding', h.areaLabel),
            for (final y in h.years)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 34,
                      child: pw.Text(
                        '${y.year}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (1000 * y.hours / most).round().clamp(
                              1,
                              1000,
                            ),
                            child: pw.Container(
                              height: 11,
                              decoration: pw.BoxDecoration(
                                borderRadius: pw.BorderRadius.circular(3),
                                gradient: pw.LinearGradient(
                                  colors: [_tint(0.55), _brand],
                                ),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: (1000 - 1000 * y.hours / most).round().clamp(
                              1,
                              1000,
                            ),
                            child: pw.SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      width: 190,
                      child: pw.Text(
                        '${groupDigits(y.hours)} h over ${y.days} days'
                        '${y.worstMonth == null ? '' : '  ·  worst ${y.worstMonth!.split(' ').first}'}',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9.5, color: _ink),
                      ),
                    ),
                  ],
                ),
              ),
            if (h.summary.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                pdfText(h.summary),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: _ink,
                  lineSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
      _note(h.caveat),
    ];
  }

  /// Drinking water: the authority's Blue Drop score on the report's own scale.
  List<pw.Widget> _waterBlock(WaterQuality water) {
    const bands = [
      ('Critical', 0.0, 31.0, PdfColor.fromInt(0xFFD7392E)),
      ('Poor', 31.0, 50.0, PdfColor.fromInt(0xFFEE7B37)),
      ('Average', 50.0, 80.0, PdfColor.fromInt(0xFFF2B233)),
      ('Good', 80.0, 90.0, PdfColor.fromInt(0xFF8CBF3F)),
      ('Excellent', 90.0, 100.0, PdfColor.fromInt(0xFF2E9E5B)),
    ];
    final score = water.scorePct.clamp(0, 100).toDouble();
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _areaHeading(
              'humidity',
              'Drinking water',
              '${water.authority}  ·  Blue Drop ${water.year}',
            ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 110,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF5F6F8),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${water.scorePct.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.Text(
                        water.band,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: water.scorePct >= 90
                              ? const PdfColor.fromInt(0xFF2E9E5B)
                              : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints!.maxWidth;
                      return pw.SizedBox(
                        height: 38,
                        child: pw.Stack(
                          children: [
                            pw.Positioned(
                              left: 0,
                              right: 0,
                              top: 12,
                              child: pw.Row(
                                children: [
                                  for (final (_, from, to, colour) in bands)
                                    pw.Expanded(
                                      flex: ((to - from) * 10).round(),
                                      child: pw.Container(
                                        height: 8,
                                        color: colour,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            pw.Positioned(
                              left: 0,
                              right: 0,
                              top: 24,
                              child: pw.Row(
                                children: [
                                  for (final (name, from, to, _) in bands)
                                    pw.Expanded(
                                      flex: ((to - from) * 10).round(),
                                      child: pw.Text(
                                        name,
                                        textAlign: pw.TextAlign.center,
                                        style: const pw.TextStyle(
                                          fontSize: 7.5,
                                          color: _muted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // This municipality, on the scale.
                            pw.Positioned(
                              left: (width * score / 100 - 5).clamp(
                                0,
                                width - 10,
                              ),
                              top: 11,
                              child: pw.Column(
                                children: [
                                  pw.Container(
                                    width: 10,
                                    height: 10,
                                    decoration: pw.BoxDecoration(
                                      color: _ink,
                                      shape: pw.BoxShape.circle,
                                      border: pw.Border.all(
                                        color: PdfColors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _note(
        'How well the municipality manages and treats its drinking water, audited by the Department of '
        'Water and Sanitation (95% and more is Blue Drop certified). A municipal score, not a test of the '
        'water at this address.',
      ),
    ];
  }

  pw.Widget _areaHeading(String icon, String title, String? subtitle) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (packIcon(icon, _brandInkHex) case final svg?)
              pw.Container(
                width: 26,
                height: 26,
                margin: const pw.EdgeInsets.only(right: 9),
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: _tint(0.1),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.SvgImage(svg: svg),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    pdfText(title),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    pw.Text(
                      pdfText(subtitle),
                      style: const pw.TextStyle(fontSize: 10, color: _muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Figures as tiles: an icon, the number large, what it is under it.
  pw.Widget _tiles(List<(String, String, String)> items, {int perRow = 4}) {
    if (items.isEmpty) return pw.SizedBox();
    pw.Widget tile((String, String, String) t) => pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF5F6F8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (packIcon(t.$1, _brandInkHex) case final svg?)
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 7, top: 1),
              child: pw.SvgImage(svg: svg, width: 17, height: 17),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  pdfText(t.$2),
                  style: pw.TextStyle(
                    fontSize: t.$2.length > 12 ? 9.5 : 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  pdfText(t.$3),
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return pw.Column(
      children: [
        for (var r = 0; r < items.length; r += perRow)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var i = r; i < r + perRow; i++) ...[
                  if (i > r) pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: i < items.length ? tile(items[i]) : pw.SizedBox(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _note(String text) => text.isEmpty
      ? pw.SizedBox(height: 10)
      : pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, bottom: 16),
          child: pw.Text(
            pdfText(text),
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        );

  static const _bands = ['Very low', 'Low', 'Moderate', 'High', 'Very high'];
  static const _bandColours = [
    PdfColor.fromInt(0xFF2E9E5B),
    PdfColor.fromInt(0xFF8CBF3F),
    PdfColor.fromInt(0xFFF2B233),
    PdfColor.fromInt(0xFFEE7B37),
    PdfColor.fromInt(0xFFD7392E),
  ];
  static const _up = PdfColor.fromInt(0xFFD7392E);
  static const _down = PdfColor.fromInt(0xFF2E9E5B);

  String _hex(PdfColor c) =>
      (c.toInt() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

  List<pw.Widget> _crimeBlock(CrimeStats c) {
    final active = c.band == null
        ? -1
        : _bands.indexWhere((b) => b.toLowerCase() == c.band!.toLowerCase());
    final shown = c.crimes
        .where((x) => x.count > 0 || x.previousCount > 0)
        .take(7)
        .toList();
    final most = shown.fold<int>(1, (m, x) => x.count > m ? x.count : m);
    final change = c.change;
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _areaHeading(
              'shield',
              'Crime',
              '${c.precinct} police precinct  ·  ${c.period}',
            ),
            // Where the precinct sits among all of South Africa's.
            pw.Row(
              children: [
                for (var i = 0; i < _bands.length; i++) ...[
                  if (i > 0) pw.SizedBox(width: 3),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: i == active
                            ? _bandColours[i]
                            : PdfColor(
                                1 - (1 - _bandColours[i].red) * 0.18,
                                1 - (1 - _bandColours[i].green) * 0.18,
                                1 - (1 - _bandColours[i].blue) * 0.18,
                              ),
                        borderRadius: pw.BorderRadius.horizontal(
                          left: pw.Radius.circular(i == 0 ? 6 : 0),
                          right: pw.Radius.circular(
                            i == _bands.length - 1 ? 6 : 0,
                          ),
                        ),
                      ),
                      child: pw.Text(
                        _bands[i],
                        style: pw.TextStyle(
                          fontSize: i == active ? 9.5 : 8.5,
                          fontWeight: i == active ? pw.FontWeight.bold : null,
                          color: i == active ? PdfColors.white : _muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 7),
            pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 11, color: _ink),
                children: [
                  pw.TextSpan(
                    text: groupDigits(c.total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  const pw.TextSpan(text: ' serious crimes reported'),
                  if (c.totalPer100k != null)
                    pw.TextSpan(
                      text:
                          '  (${groupDigits(c.totalPer100k!)} per 100 000 residents)',
                    ),
                  if (change != null)
                    pw.TextSpan(
                      text:
                          '  ·  ${change >= 0 ? 'up' : 'down'} ${change.abs().toStringAsFixed(0)}% on the year before',
                      style: pw.TextStyle(
                        color: change >= 0 ? _up : _down,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            for (final x in shown)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 170,
                      child: pw.Text(
                        pdfText(x.crime),
                        style: const pw.TextStyle(fontSize: 9.5, color: _ink),
                        maxLines: 1,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (1000 * x.count / most).round().clamp(
                              1,
                              1000,
                            ),
                            child: pw.Container(
                              height: 9,
                              decoration: pw.BoxDecoration(
                                // A fixed slate, whatever the brand: a green or yellow bar
                                // would read as good news.
                                color: const PdfColor.fromInt(0xFF7A8490),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: (1000 - 1000 * x.count / most).round().clamp(
                              1,
                              1000,
                            ),
                            child: pw.SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      width: 40,
                      child: pw.Text(
                        groupDigits(x.count),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 58,
                      child: x.previousCount == 0
                          ? pw.SizedBox()
                          : pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                if (packIcon(
                                      x.count >= x.previousCount
                                          ? 'up'
                                          : 'down',
                                      _hex(
                                        x.count >= x.previousCount
                                            ? _up
                                            : _down,
                                      ),
                                    )
                                    case final svg?)
                                  pw.SvgImage(svg: svg, width: 10, height: 10),
                                pw.SizedBox(width: 3),
                                pw.Text(
                                  '${((x.count - x.previousCount) * 100 / x.previousCount).abs().toStringAsFixed(0)}%',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: x.count >= x.previousCount
                                        ? _up
                                        : _down,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      _note(
        'Compared with every police precinct in South Africa, per resident. Figures are for the whole precinct; '
        'precincts with a town centre, beachfront or shopping area count crimes against visitors too, so their '
        'rate per resident reads higher.',
      ),
    ];
  }

  static const _monthLetters = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];
  static const _rainColour = PdfColor.fromInt(0xFF5B8DEF);
  static const _highColour = PdfColor.fromInt(0xFFE0433A);
  static const _lowColour = PdfColor.fromInt(0xFFF2A33A);

  List<pw.Widget> _climateBlock(Climate w) {
    final tiles = <(String, String, String)>[
      (
        'temperature',
        '${w.avgMaxC.toStringAsFixed(0)}° / ${w.avgMinC.toStringAsFixed(0)}°',
        'Average high / low (°C)',
      ),
      (
        'rain',
        '${groupDigits(w.annualRainMm)} mm',
        w.rainDaysPerYear == null
            ? 'Rain a year'
            : 'Rain a year, over ${w.rainDaysPerYear} days',
      ),
      if (w.solarKwhM2Day != null)
        (
          'sun',
          '${w.solarKwhM2Day!.toStringAsFixed(1)} kWh/m²',
          'Sunshine a day (for solar)',
        ),
      if (w.hotDaysPerYear != null)
        ('heat', '${w.hotDaysPerYear} days', 'Over 30 °C a year'),
      if (w.humidityPct != null)
        ('humidity', '${w.humidityPct!.round()}%', 'Average humidity'),
      if (w.windMs != null)
        ('wind', '${w.windMs!.toStringAsFixed(1)} m/s', 'Average wind'),
    ];
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _areaHeading(
              'sun',
              'Weather and climate',
              'Averages for ${w.years}  ·  hottest ${w.hottestMonth}, coldest ${w.coldestMonth}',
            ),
            _tiles(tiles, perRow: 3),
            if (w.months.length == 12) ...[
              pw.SizedBox(height: 6),
              _climateChart(w.months),
            ],
            // Inside, so the note never lands on a page of its own.
            _note(
              'A regional average (about 50 km), not a street-level reading.',
            ),
          ],
        ),
      ),
    ];
  }

  /// Rain per month as bars, the average high and low as lines over them.
  pw.Widget _climateChart(List<ClimateMonth> months) {
    const height = 96.0;
    final maxRain =
        months.fold<double>(10, (m, x) => x.rainMm > m ? x.rainMm : m) * 1.15;
    final maxTemp =
        months.fold<double>(10, (m, x) => x.avgMaxC > m ? x.avgMaxC : m) + 4;
    final minTemp = months.fold<double>(
      0,
      (m, x) => x.avgMinC < m ? x.avgMinC : m,
    );
    pw.Widget legend(PdfColor colour, String text, {bool line = false}) =>
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 12,
              height: line ? 2.5 : 8,
              color: colour,
              margin: const pw.EdgeInsets.only(right: 4),
            ),
            pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
            pw.SizedBox(width: 12),
          ],
        );
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              legend(_rainColour, 'Rain (mm)'),
              legend(_highColour, 'Average high (°C)', line: true),
              legend(_lowColour, 'Average low (°C)', line: true),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.SizedBox(
            height: height,
            child: pw.Stack(
              children: [
                // Bars and lines, drawn to the box.
                pw.Positioned.fill(
                  child: pw.CustomPaint(
                    painter: (PdfGraphics g, PdfPoint size) {
                      final slot = size.x / 12;
                      double tempY(double t) =>
                          (t - minTemp) / (maxTemp - minTemp) * size.y;
                      // Light guide lines.
                      g.setStrokeColor(_rule);
                      g.setLineWidth(0.4);
                      for (var k = 1; k <= 3; k++) {
                        g.drawLine(0, size.y * k / 4, size.x, size.y * k / 4);
                      }
                      g.strokePath();
                      g.setFillColor(_rainColour);
                      for (var i = 0; i < 12; i++) {
                        final h = months[i].rainMm / maxRain * size.y;
                        g.drawRRect(
                          slot * i + slot * 0.2,
                          0,
                          slot * 0.6,
                          h,
                          2,
                          2,
                        );
                      }
                      g.fillPath();
                      for (final (colour, of) in [
                        (_highColour, (ClimateMonth m) => m.avgMaxC),
                        (_lowColour, (ClimateMonth m) => m.avgMinC),
                      ]) {
                        g.setStrokeColor(colour);
                        g.setLineWidth(1.8);
                        for (var i = 0; i < 12; i++) {
                          final x = slot * i + slot / 2;
                          final y = tempY(of(months[i]));
                          if (i == 0) {
                            g.moveTo(x, y);
                          } else {
                            g.lineTo(x, y);
                          }
                        }
                        g.strokePath();
                        g.setFillColor(colour);
                        for (var i = 0; i < 12; i++) {
                          g.drawEllipse(
                            slot * i + slot / 2,
                            tempY(of(months[i])),
                            1.8,
                            1.8,
                          );
                        }
                        g.fillPath();
                      }
                    },
                  ),
                ),
                // The high above each month's point.
                pw.Positioned.fill(
                  child: pw.Row(
                    children: [
                      for (final m in months)
                        pw.Expanded(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${m.avgMaxC.round()}°',
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  color: _highColour,
                                ),
                              ),
                              pw.SizedBox(
                                height:
                                    (m.avgMaxC - minTemp) /
                                        (maxTemp - minTemp) *
                                        height +
                                    2,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              for (var i = 0; i < 12; i++)
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        _monthLetters[i],
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.Text(
                        '${months[i].rainMm.round()} mm',
                        style: const pw.TextStyle(fontSize: 7, color: _muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- homes on the market ------------------------------------------------------

  List<pw.Widget> _marketPage(ForSale f) {
    return [
      _sectionTitle('Homes on the market like yours'),
      pw.Text(
        pdfText(
          'Homes for sale near ${report.displayAddress}; each links to its listing.',
        ),
        style: const pw.TextStyle(fontSize: 9.5, color: _muted),
      ),
      pw.SizedBox(height: 10),
      for (final l in f.listings) pw.Inseparable(child: _listingCard(l)),
    ];
  }

  /// A home for sale as the cover shows ours: the main photo and three more
  /// with black lines between, then the price, where it is, and its features
  /// as icons. Black text; only the price and the link in the brand colour.
  pw.Widget _listingCard(ForSaleListing l) {
    final main = _img(pictures.listingPhotos[l.listingNumber]);
    final more = [
      for (final p
          in pictures.listingMorePhotos[l.listingNumber] ?? const <Uint8List>[])
        ?_img(p),
    ].take(3).toList();
    String n(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
    final facts = <(String, String, String)>[
      if (l.bedrooms != null) ('bedrooms', n(l.bedrooms!), 'Bedrooms'),
      if (l.bathrooms != null) ('bathrooms', n(l.bathrooms!), 'Bathrooms'),
      if (l.parking != null) ('parking', n(l.parking!), 'Parking'),
      if (l.floorM2 != null)
        ('floor', '${groupDigits(l.floorM2!)} m²', 'Floor size'),
      if (l.erfM2 != null) ('erf', '${groupDigits(l.erfM2!)} m²', 'Erf size'),
    ];
    final distance = l.distanceM == null
        ? null
        : l.distanceM! < 1000
        ? '${(l.distanceM! / 10).round() * 10} m away'
        : '${(l.distanceM! / 1000).toStringAsFixed(1)} km away';
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Photos: black shows through the gaps as lines.
          pw.Container(
            width: 250,
            color: PdfColors.black,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(
                  height: 150,
                  child: main == null
                      ? pw.Container(color: const PdfColor.fromInt(0xFFF5F6F8))
                      : pw.Image(main, fit: pw.BoxFit.cover),
                ),
                if (more.isNotEmpty) ...[
                  pw.SizedBox(height: 1.5),
                  pw.Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) pw.SizedBox(width: 1.5),
                        pw.Expanded(
                          child: pw.SizedBox(
                            height: 52,
                            child: i < more.length
                                ? pw.Image(more[i], fit: pw.BoxFit.cover)
                                : pw.Container(
                                    color: const PdfColor.fromInt(0xFFF5F6F8),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 9, 10, 9),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l.priceZar == null
                        ? 'Price on application'
                        : rand(l.priceZar!),
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: _brandInk,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    pdfText(l.title),
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    pdfText(
                      [l.address, l.suburb].whereType<String>().join(', '),
                    ),
                    style: const pw.TextStyle(fontSize: 10, color: _ink),
                  ),
                  if (distance != null)
                    pw.Row(
                      children: [
                        if (packIcon('place', _hex(_ink)) case final svg?)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(right: 3),
                            child: pw.SvgImage(svg: svg, width: 10, height: 10),
                          ),
                        pw.Text(
                          distance,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 9),
                  for (var r = 0; r < facts.length; r += 3)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Row(
                        children: [
                          for (var i = r; i < r + 3; i++)
                            pw.Expanded(
                              child: i < facts.length
                                  ? _smallFact(
                                      facts[i].$1,
                                      facts[i].$2,
                                      facts[i].$3,
                                    )
                                  : pw.SizedBox(),
                            ),
                        ],
                      ),
                    ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      if (l.listedOn != null)
                        pw.Expanded(
                          child: pw.Text(
                            'Listed ${_shortDay.format(l.listedOn!)}',
                            style: const pw.TextStyle(fontSize: 9, color: _ink),
                          ),
                        )
                      else
                        pw.Spacer(),
                      pw.UrlLink(
                        destination: l.url,
                        child: pw.Text(
                          'View on Property24',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            color: _brandInk,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _smallFact(String icon, String value, String label) => pw.Row(
    children: [
      if (packIcon(icon, _brandInkHex) case final svg?)
        pw.SvgImage(svg: svg, width: 15, height: 15),
      pw.SizedBox(width: 5),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            pdfText(value),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: _ink)),
        ],
      ),
    ],
  );

  // ---- property inspection ---------------------------------------------------

  /// The agent's walk-through: the home as a whole, every room with its
  /// condition and score, and outside.
  List<pw.Widget> _inspectionPage(PackInspection v) {
    const cell = pw.TextStyle(fontSize: 10, color: _ink);
    final bold = pw.TextStyle(
      fontSize: 10,
      color: _ink,
      fontWeight: pw.FontWeight.bold,
    );
    // The app's condition colours, red to green.
    PdfColor conditionColour(int level) => switch (level) {
      <= 2 => const PdfColor.fromInt(0xFFD9534F),
      3 => const PdfColor.fromInt(0xFF8A95A1),
      _ => const PdfColor.fromInt(0xFF2E9E5B),
    };
    return [
      _sectionTitle('Property inspection'),
      pw.Text(
        pdfText(
          'What ${agent.name.isEmpty ? 'your agent' : agent.name} found walking through the home'
          '${v.houseScore == null ? '.' : ': an overall score of ${v.houseScore!.round()}%.'}',
        ),
        style: const pw.TextStyle(fontSize: 10.5, color: _ink),
      ),
      pw.SizedBox(height: 10),
      if (v.building.isNotEmpty) ...[
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in v.building)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _tint(0.08),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(pdfText(b), style: cell),
              ),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
      pw.TableHelper.fromTextArray(
        headers: ['Room', 'Condition', 'Score', 'Features and notes'],
        data: [
          for (final r in v.rooms)
            [
              pdfText(r.name),
              r.condition.isEmpty ? '-' : r.condition,
              r.score == null
                  ? '-'
                  : '${r.score! == r.score!.roundToDouble() ? r.score!.round() : r.score} / 10',
              pdfText(
                [
                  if (r.features.isNotEmpty) r.features.join(', '),
                  if (r.notes.trim().isNotEmpty) r.notes.trim(),
                ].join('. '),
              ),
            ],
        ],
        headerStyle: pw.TextStyle(color: _onBrand, fontSize: 10),
        headerDecoration: pw.BoxDecoration(color: _brand),
        cellStyle: cell,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        border: null,
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
        ),
        // Room names in bold; the condition in its colour.
        textStyleBuilder: (col, _, row) {
          if (row == 0) return null;
          if (col == 0) return bold;
          final level = v.rooms[row - 1].conditionLevel;
          return col == 1 && level != null
              ? bold.copyWith(color: conditionColour(level))
              : cell;
        },
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1.4),
          2: pw.FlexColumnWidth(0.9),
          3: pw.FlexColumnWidth(4.2),
        },
      ),
      if (v.outside.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        pw.Text('Outside', style: bold.copyWith(fontSize: 11.5)),
        pw.SizedBox(height: 4),
        pw.Text(pdfText(v.outside.join(', ')), style: cell),
      ],
    ];
  }

  // ---- valuation letter ------------------------------------------------------------

  pw.Widget _letter() {
    final signature = _img(pictures.signature);
    const body = pw.TextStyle(fontSize: 12, color: _ink, lineSpacing: 2.5);
    final bold = pw.TextStyle(
      fontSize: 12,
      color: _ink,
      fontWeight: pw.FontWeight.bold,
      lineSpacing: 2.5,
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
        _moneyText(
          'Having considered all of this, we estimate the current market value '
          'of your property at between ${rand(valuation.low)} and '
          '${rand(valuation.high)}, and recommend a listing price of '
          '${rand(valuation.listingPrice)} to allow room for negotiation.',
          body,
          moneyStyle: bold,
        ),
        if (_letterEvidence() case final evidence?) ...[
          pw.SizedBox(height: 8),
          _moneyText(pdfText(evidence), body),
        ],
        if (_letterRent() case final rent?) ...[
          pw.SizedBox(height: 8),
          _moneyText(pdfText(rent), body),
        ],
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
            bulletColor: _brandInk,
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
        else if (_signatureFont case final font?)
          // No signature of their own yet: their name in a handwriting face,
          // as My Profile shows it.
          pw.Text(
            pdfText(agent.name),
            style: pw.TextStyle(
              font: font,
              fontSize: 26,
              color: const PdfColor.fromInt(0xFF16265C),
            ),
          )
        else
          pw.SizedBox(height: 26),
        pw.SizedBox(height: 6),
        _businessCard(),
        pw.Spacer(),
        _officeFooter(),
      ],
    );
  }

  /// The letter's specifics: what the sales used show, the nearest of them,
  /// and why the agent's range differs from the sales' when it does, so the
  /// letter and the analysis never disagree unexplained.
  String? _letterEvidence() {
    final used = report.includedComparables;
    // The most recent sale: the one a seller will recognise as today's market.
    final recent = ([
      ...used,
    ]..sort((a, b) => b.saleDate.compareTo(a.saleDate))).firstOrNull;
    final radius = report.comparableSummary?.radiusM;
    final data = report.bestRange;
    final parts = [
      if (used.isNotEmpty)
        'It rests on ${used.length} recorded sales'
            '${radius == null ? ' nearby' : ' within $radius m of the property'}'
            '${recent == null ? '' : '; the most recent, ${_title(report.withoutSuburb(recent.address))}${recent.distanceM == null ? '' : ' (${_distance(recent.distanceM!)} away)'}, ${recent.dwellingExtentM2 > 0 ? 'a ${recent.dwellingExtentM2.round()} m² home, ' : ''}sold for ${rand(recent.salePriceZar)} in ${DateFormat('MMMM yyyy').format(recent.saleDate)}'}.',
      if (data?.low case final low?)
        if (data?.high case final high?)
          if ((valuation.low / low - 1).abs() > 0.05 ||
              (valuation.high / high - 1).abs() > 0.05)
            'Those sales alone indicate ${rand(low)} to ${rand(high)}; our '
                'estimate is ${valuation.high > high ? 'higher' : 'lower'} '
                '${valuation.adjustmentReason.trim().isEmpty ? 'because it also reflects our inspection of the home' : 'to allow for ${valuation.adjustmentReason.trim().replaceAll(RegExp(r'[.\s]+$'), '')}'}.',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// The let flatlet(s) as income: what it brings in a month and a year, and
  /// that share of the asking price, which supports the price and widens
  /// the buyers it suits (a buyer may count rent towards a bond).
  String? _letterRent() {
    final rents = listing.flatletRents.where((r) => r > 0).toList();
    if (rents.isEmpty) return null;
    final month = rents.fold<double>(0, (a, b) => a + b);
    final year = month * 12;
    final share = valuation.listingPrice > 0
        ? year / valuation.listingPrice * 100
        : null;
    final what = rents.length == 1
        ? 'The flatlet is let at ${rand(month)} a month'
        : 'The ${rents.length} flatlets are let for ${rand(month)} a month together';
    return '$what, ${rand(year)} a year'
        '${share == null ? '' : ' (${share.toStringAsFixed(1)}% of the asking price)'}. '
        'That income supports the price and widens the market: it suits buyers '
        'looking for help with the bond as well as investors, and lenders may '
        'take part of it into account.';
  }

  /// [text] with every amount ("R 5 000 000") kept on one line, in
  /// [moneyStyle] when given. The pdf package breaks lines at any whitespace,
  /// the non-breaking spaces between digit groups included.
  static pw.Widget _moneyText(
    String text,
    pw.TextStyle style, {
    pw.TextStyle? moneyStyle,
  }) {
    final spans = <pw.InlineSpan>[];
    var at = 0;
    for (final m in RegExp(
      r'R[\s\u00A0]\d{1,3}(?:[\s\u00A0]\d{3})*',
    ).allMatches(text)) {
      if (m.start > at) {
        spans.add(pw.TextSpan(text: text.substring(at, m.start)));
      }
      spans.add(
        pw.WidgetSpan(
          // Down by the font's descent, onto the line's baseline.
          baseline: -0.22 * (style.fontSize ?? 12),
          child: pw.Text(m[0]!, style: style.merge(moneyStyle)),
        ),
      );
      at = m.end;
    }
    if (at < text.length) spans.add(pw.TextSpan(text: text.substring(at)));
    return pw.RichText(
      text: pw.TextSpan(style: style, children: spans),
    );
  }

  /// The sign-off as the agent's business card: photo, name and title, how to
  /// reach them, and their registrations.
  pw.Widget _businessCard() {
    // Head and shoulders, so the face sits in the middle of the circle.
    final photo = _img(
      ValuationReportPdf.isEmbeddableImage(pictures.agentPhoto)
          ? headAndShoulders(pictures.agentPhoto!)
          : null,
    );
    final contacts = [
      if (agent.mobile.isNotEmpty) ('phone', agent.mobile),
      if (agent.email.isNotEmpty) ('email', agent.email),
      if (agent.website.isNotEmpty) ('website', agent.website),
    ];
    final registrations = [
      if (agent.ppraNumber.isNotEmpty)
        'Registered with the PPRA, no. ${agent.ppraNumber}',
      if (agent.ffcNumber.isNotEmpty) 'FFC no. ${agent.ffcNumber}',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _tint(0.07),
        border: pw.Border(left: pw.BorderSide(color: _brand, width: 4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (photo != null) ...[
            pw.ClipOval(
              child: pw.SizedBox(
                width: 64,
                height: 64,
                child: pw.Image(photo, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  pdfText(agent.name),
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (agent.jobTitle.isNotEmpty)
                  pw.Text(
                    pdfText(agent.jobTitle),
                    style: const pw.TextStyle(fontSize: 11.5, color: _ink),
                  ),
                if (registrations.isNotEmpty) pw.SizedBox(height: 3),
                for (final line in registrations)
                  pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 10, color: _ink),
                  ),
              ],
            ),
          ),
          if (contacts.isNotEmpty) ...[
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final (icon, value) in contacts)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                      children: [
                        if (packIcon(icon, _brandInkHex) case final svg?)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(right: 6),
                            child: pw.SvgImage(svg: svg, width: 10, height: 10),
                          ),
                        pw.Text(
                          value,
                          style: const pw.TextStyle(fontSize: 11, color: _ink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---- costs ---------------------------------------------------------------------

  pw.Widget _costsPage() {
    const body = pw.TextStyle(fontSize: 10.5, color: _ink, lineSpacing: 1.5);
    final bold = pw.TextStyle(
      fontSize: 10.5,
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
              color: _brandInk,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'The seller (estimate; commission can be negotiated)',
          style: pw.TextStyle(
            fontSize: 12,
            color: _brandInk,
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
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'The buyer (estimate)',
          style: pw.TextStyle(
            fontSize: 12,
            color: _brandInk,
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
            fontSize: 12,
            color: _brandInk,
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
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
        pw.Spacer(),
        _officeFooter(),
      ],
    );
  }
}
