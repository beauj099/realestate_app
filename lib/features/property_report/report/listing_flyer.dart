import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/property_report.dart' show rand;
import 'pack_icons.dart';
import 'report_fonts.dart';
import 'pack_listing.dart' show PackFacts;
import 'valuation_report_pdf.dart';

/// The shapes a flyer comes in: a square post and a story for social media
/// (shared as pictures), and A5 to print or hand out.
enum FlyerFormat {
  square(1080, 1080),
  story(1080, 1920),
  a5(419.53, 595.28);

  final double width;
  final double height;
  const FlyerFormat(this.width, this.height);

  bool get isImage => this != a5;
}

/// A "For sale" flyer for a listing in the agency's colours: the main photo
/// (and two more on the taller shapes), the asking price, the address (by
/// the area buyers search for), the home's facts as icons, and the agent's
/// name and number with the agency's logo. Nothing about the owners or the
/// valuation.
class ListingFlyer {
  final String street;

  /// The marketing area and town, e.g. "Steynsrust, Somerset West".
  final String area;
  final double? askingPrice;
  final PackFacts facts;

  /// One line that sells it, e.g. "Family home with a flatlet"; optional.
  final String headline;
  final Uint8List? mainPhoto;
  final List<Uint8List> morePhotos;
  final String agentName;
  final String agentPhone;
  final String agencyName;
  final Uint8List? logo;
  final Color brandColor;
  final Color onBrandColor;

  const ListingFlyer({
    required this.street,
    required this.area,
    required this.askingPrice,
    required this.facts,
    this.headline = '',
    this.mainPhoto,
    this.morePhotos = const [],
    required this.agentName,
    required this.agentPhone,
    required this.agencyName,
    this.logo,
    required this.brandColor,
    this.onBrandColor = const Color(0xFFFFFFFF),
  });

  PdfColor get _brand => PdfColor.fromInt(brandColor.toARGB32());
  PdfColor get _onBrand => PdfColor.fromInt(onBrandColor.toARGB32());
  String get _onBrandHex =>
      (onBrandColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

  static pw.ImageProvider? _img(Uint8List? bytes) =>
      ValuationReportPdf.isEmbeddableImage(bytes)
      ? pw.MemoryImage(bytes!)
      : null;

  String fileName(FlyerFormat f) =>
      'For sale - ${street.replaceAll(',', '')}'
      '${f == FlyerFormat.a5 ? '.pdf' : ' (${f.name}).png'}';

  /// The flyer as a one-page PDF in [format].
  Future<Uint8List> pdf(FlyerFormat format) async {
    final doc = pw.Document(
      title: 'For sale - $street',
      creator: 'RealWorth',
      theme: await reportTheme(),
    );
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(format.width, format.height),
        margin: pw.EdgeInsets.zero,
        build: (_) => _page(format),
      ),
    );
    return doc.save();
  }

  /// The flyer as a PNG, for social media: the square post is 1080 × 1080
  /// pixels and the story 1080 × 1920.
  Future<Uint8List> png(FlyerFormat format) async {
    assert(format.isImage);
    final bytes = await pdf(format);
    // The page is sized in points; 72 dpi makes one point one pixel.
    final page = await Printing.raster(bytes, dpi: 72).first;
    return page.toPng();
  }

  /// Sizes scale with the page: the A5 page is about 0.39 of the square's.
  pw.Widget _page(FlyerFormat f) {
    final k = f.width / 1080;
    final main = _img(mainPhoto);
    final extras = [for (final p in morePhotos) ?_img(p)].take(2).toList();
    final photoHeight = switch (f) {
      FlyerFormat.square => 620 * k,
      FlyerFormat.story => 900 * k,
      FlyerFormat.a5 => 300.0,
    };
    final showExtras = f != FlyerFormat.square && extras.length == 2;
    final logoImage = _img(logo);

    pw.Widget photo(pw.ImageProvider? image) => image == null
        ? pw.Container(color: _brand)
        : pw.Image(image, fit: pw.BoxFit.cover);

    return pw.Container(
      color: _brand,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(
            height: photoHeight,
            child: pw.Stack(
              children: [
                pw.Positioned.fill(child: photo(main)),
                pw.Positioned(
                  left: 40 * k,
                  top: 40 * k,
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: 26 * k,
                      vertical: 12 * k,
                    ),
                    color: _brand,
                    child: pw.Text(
                      'FOR SALE',
                      style: pw.TextStyle(
                        color: _onBrand,
                        fontSize: 40 * k,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 4 * k,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showExtras)
            pw.SizedBox(
              height: photoHeight * 0.42,
              child: pw.Row(
                children: [
                  pw.Expanded(child: photo(extras[0])),
                  pw.SizedBox(width: 4 * k),
                  pw.Expanded(child: photo(extras[1])),
                ],
              ),
            ),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(48 * k, 34 * k, 48 * k, 36 * k),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (askingPrice case final price? when price > 0)
                    pw.Text(
                      rand(price),
                      style: pw.TextStyle(
                        color: _onBrand,
                        fontSize: 76 * k,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  pw.SizedBox(height: 6 * k),
                  pw.Text(
                    pdfText(street),
                    style: pw.TextStyle(
                      color: _onBrand,
                      fontSize: 38 * k,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  if (area.isNotEmpty)
                    pw.Text(
                      pdfText(area),
                      style: pw.TextStyle(color: _onBrand, fontSize: 32 * k),
                      maxLines: 1,
                    ),
                  if (headline.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 10 * k),
                    pw.Text(
                      pdfText(headline.trim()),
                      style: pw.TextStyle(
                        color: _onBrand,
                        fontSize: 30 * k,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      maxLines: 2,
                    ),
                  ],
                  pw.SizedBox(height: 22 * k),
                  _facts(k),
                  pw.Spacer(),
                  _footer(k, logoImage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Beds, baths, garages, floor area and erf, each an icon and a number.
  pw.Widget _facts(double k) {
    String n(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
    final items = [
      if (facts.bedrooms > 0) ('bedrooms', n(facts.bedrooms), 'Beds'),
      if (facts.bathrooms > 0) ('bathrooms', n(facts.bathrooms), 'Baths'),
      if (facts.garages > 0) ('garages', n(facts.garages), 'Garages'),
      if (facts.floorM2 case final f?) ('floor', '${f.round()} m²', 'Floor'),
      if (facts.erfM2 case final e?) ('erf', '${e.round()} m²', 'Erf'),
    ].take(5).toList();
    return pw.Wrap(
      spacing: 34 * k,
      runSpacing: 12 * k,
      children: [
        for (final (icon, value, label) in items)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (packIcon(icon, _onBrandHex) case final svg?)
                pw.SvgImage(svg: svg, width: 40 * k, height: 40 * k),
              pw.SizedBox(width: 10 * k),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    value,
                    style: pw.TextStyle(
                      color: _onBrand,
                      fontSize: 30 * k,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    label,
                    style: pw.TextStyle(color: _onBrand, fontSize: 20 * k),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  /// The agent and the agency: who to call.
  pw.Widget _footer(double k, pw.ImageProvider? logo) => pw.Container(
    padding: pw.EdgeInsets.only(top: 18 * k),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: _onBrand, width: 1.5 * k),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                pdfText(agentName),
                style: pw.TextStyle(
                  color: _onBrand,
                  fontSize: 30 * k,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (agentPhone.isNotEmpty)
                pw.Text(
                  agentPhone,
                  style: pw.TextStyle(color: _onBrand, fontSize: 28 * k),
                ),
            ],
          ),
        ),
        if (logo != null)
          pw.Container(
            height: 90 * k,
            width: 260 * k,
            padding: pw.EdgeInsets.all(10 * k),
            color: PdfColors.white,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          )
        else
          pw.Text(
            pdfText(agencyName),
            style: pw.TextStyle(
              color: _onBrand,
              fontSize: 28 * k,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
      ],
    ),
  );
}
