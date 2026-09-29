import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// The reports' typeface: Lato (SIL Open Font Licence,
/// `assets/fonts/Lato-OFL.txt`), embedded and subset by the pdf package. Unlike
/// the built-in PDF fonts it has proper dashes, quotes and accents.
Future<pw.ThemeData> reportTheme() => _theme ??= _load();

Future<pw.ThemeData>? _theme;

/// The serif for headings of brands with a serif identity: Crimson Text (SIL
/// Open Font Licence, `assets/fonts/CrimsonText-OFL.txt`), regular and bold.
Future<(pw.Font, pw.Font)> reportSerif() => _serif ??= () async {
  Future<pw.Font> font(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
  return (await font('CrimsonText-Regular'), await font('CrimsonText-Bold'));
}();

Future<(pw.Font, pw.Font)>? _serif;

Future<pw.ThemeData> _load() async {
  Future<pw.Font> font(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
  final fonts = await Future.wait([
    font('Lato-Regular'),
    font('Lato-Bold'),
    font('Lato-Italic'),
    font('Lato-BoldItalic'),
  ]);
  return pw.ThemeData.withFont(
    base: fonts[0],
    bold: fonts[1],
    italic: fonts[2],
    boldItalic: fonts[3],
  );
}
