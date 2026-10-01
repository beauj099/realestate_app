import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'property_report_repository.dart';

/// A finished valuation report for one listing, as the API sent it, kept on
/// the phone so reopening the report shows it at once instead of asking the
/// City again (10–30 s). Google imagery is never kept: its terms forbid
/// storing it, so it is fetched again when there is any.
class ReportSnapshot {
  /// What the report was made for (the listing's address, erf and pin); a
  /// snapshot only counts while the listing still says the same.
  final String key;
  final DateTime generatedAt;
  final Map<String, dynamic> candidate;
  final Map<String, dynamic> report;
  final String? sitePlanSvg;
  final String? areaMapSvg;
  final String? blockMapSvg;
  final List<dynamic> market;
  final Map<String, dynamic>? area;
  final Map<String, dynamic>? forSale;

  /// The bedrooms and sizes homes for sale were matched to; when the
  /// listing's differ now, only those homes are looked up again.
  final String? hintsKey;

  const ReportSnapshot({
    required this.key,
    this.hintsKey,
    required this.generatedAt,
    required this.candidate,
    required this.report,
    this.sitePlanSvg,
    this.areaMapSvg,
    this.blockMapSvg,
    this.market = const [],
    this.area,
    this.forSale,
  });

  ReportSnapshot copyWith({
    Map<String, dynamic>? report,
    Map<String, dynamic>? area,
    Map<String, dynamic>? forSale,
    String? hintsKey,
  }) => ReportSnapshot(
    key: key,
    hintsKey: hintsKey ?? this.hintsKey,
    generatedAt: generatedAt,
    candidate: candidate,
    report: report ?? this.report,
    sitePlanSvg: sitePlanSvg,
    areaMapSvg: areaMapSvg,
    blockMapSvg: blockMapSvg,
    market: market,
    area: area ?? this.area,
    forSale: forSale ?? this.forSale,
  );

  /// The key for a lookup: the same listing data gives the same key.
  static String keyFor(ReportQuery q) => [
    q.address.trim().toLowerCase(),
    q.erf?.trim() ?? '',
    q.lat?.toStringAsFixed(5) ?? '',
    q.lng?.toStringAsFixed(5) ?? '',
  ].join('|');

  Map<String, dynamic> toJson() => {
    'version': 1,
    'key': key,
    'hintsKey': hintsKey,
    'generatedAt': generatedAt.toIso8601String(),
    'candidate': candidate,
    'report': report,
    'sitePlanSvg': sitePlanSvg,
    'areaMapSvg': areaMapSvg,
    'blockMapSvg': blockMapSvg,
    'market': market,
    'area': area,
    'forSale': forSale,
  };

  static ReportSnapshot? fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) return null;
    return ReportSnapshot(
      key: j['key'] as String,
      hintsKey: j['hintsKey'] as String?,
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      candidate: j['candidate'] as Map<String, dynamic>,
      report: j['report'] as Map<String, dynamic>,
      sitePlanSvg: j['sitePlanSvg'] as String?,
      areaMapSvg: j['areaMapSvg'] as String?,
      blockMapSvg: j['blockMapSvg'] as String?,
      market: j['market'] as List? ?? const [],
      area: j['area'] as Map<String, dynamic>?,
      forSale: j['forSale'] as Map<String, dynamic>?,
    );
  }
}

/// Reads and writes [ReportSnapshot]s, one file per listing in the app's own
/// documents folder. Failures are logged, never thrown: a missing or broken
/// snapshot only means the report is generated again.
class ReportCache {
  const ReportCache();

  Future<File> _file(int listingId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/reports/listing-$listingId.json');
  }

  Future<ReportSnapshot?> load(int listingId) async {
    try {
      final file = await _file(listingId);
      if (!await file.exists()) return null;
      return ReportSnapshot.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log('Saved report unreadable: $e');
      return null;
    }
  }

  Future<void> save(int listingId, ReportSnapshot snapshot) async {
    try {
      final file = await _file(listingId);
      await file.parent.create(recursive: true);
      // Written beside it first, so a crash never leaves half a file.
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(snapshot.toJson()));
      await temp.rename(file.path);
    } catch (e) {
      developer.log('Could not save the report: $e');
    }
  }
}
