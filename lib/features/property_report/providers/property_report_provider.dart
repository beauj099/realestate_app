import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/providers/api_providers.dart';
import '../data/models/agent_sales.dart';
import '../data/models/area_details.dart';
import '../data/models/property_report.dart';
import '../data/property_report_repository.dart';
import '../data/report_cache.dart';
import 'report_preparer.dart';

final propertyReportRepositoryProvider = Provider<PropertyReportRepository>(
  (ref) => PropertyReportRepository(ref.watch(apiClientProvider)),
);

/// Where finished reports are kept on the phone, per listing.
final reportCacheProvider = Provider<ReportCache>((ref) => const ReportCache());

class PropertyReportState {
  final bool loading;
  final String? error;

  /// More than one property matched: the agent picks one.
  final List<PropertyCandidate> candidates;

  final PropertyReport? report;
  final String? sitePlanSvg;

  /// The comparable sales on a map, and the property's block close up.
  final String? areaMapSvg;
  final String? blockMapSvg;

  /// Imagery bytes keyed by [ImageryRef.url]. Held in memory only — Google's
  /// terms forbid storing them.
  final Map<String, Uint8List> images;

  /// The agency's own listings in the suburb ("on the market nearby").
  final List<MarketListing> market;

  /// Climate, population, income and crime around the property; null until
  /// loaded or when every source was down.
  final AreaDetails? area;

  /// Similar homes for sale on Property24.
  final ForSale? forSale;

  /// When the report shown was generated; null while none is.
  final DateTime? generatedAt;

  const PropertyReportState({
    this.loading = false,
    this.error,
    this.candidates = const [],
    this.report,
    this.sitePlanSvg,
    this.areaMapSvg,
    this.blockMapSvg,
    this.images = const {},
    this.market = const [],
    this.area,
    this.forSale,
    this.generatedAt,
  });

  PropertyReportState copyWith({
    PropertyReport? report,
    List<MarketListing>? market,
    AreaDetails? area,
    ForSale? forSale,
  }) => PropertyReportState(
    loading: loading,
    error: error,
    candidates: candidates,
    report: report ?? this.report,
    sitePlanSvg: sitePlanSvg,
    areaMapSvg: areaMapSvg,
    blockMapSvg: blockMapSvg,
    images: images,
    market: market ?? this.market,
    area: area ?? this.area,
    forSale: forSale ?? this.forSale,
    generatedAt: generatedAt,
  );
}

/// Loads a valuation report for one property: resolve the address to an erf,
/// then fetch the report, its site plan and imagery.
class PropertyReportNotifier extends Notifier<PropertyReportState> {
  @override
  PropertyReportState build() => const PropertyReportState();

  PropertyReportRepository get _repo =>
      ref.read(propertyReportRepositoryProvider);

  ReportCache get _cache => ref.read(reportCacheProvider);

  /// What is kept on the phone for this listing, built up as the parts load.
  ReportSnapshot? _snapshot;

  /// The listing's own details the report is filed under (see [lookUp]).
  String? _cacheKey;

  PropertyCandidate? _candidate;

  /// The listing the report is for, left out of the agency's listings nearby.
  int? _listingId;

  /// What the listing says about the home, to find similar homes for sale.
  ListingHints _hints = const ListingHints();

  /// Finds the property and its report. For a listing, the report made
  /// before is shown at once from the phone when the listing's address, erf
  /// and pin ([cacheKey]) are still what they were; [refresh] makes a new one.
  Future<void> lookUp(
    ReportQuery query, {
    int? listingId,
    ListingHints hints = const ListingHints(),
    String? cacheKey,
    bool refresh = false,
  }) async {
    _listingId = listingId;
    _hints = hints;
    _cacheKey = cacheKey ?? ReportSnapshot.keyFor(query);
    state = const PropertyReportState(loading: true);
    if (listingId != null && !refresh) {
      // Made in the background after the address was saved: wait for it
      // rather than make it twice.
      await ref.read(reportPreparerProvider).running(listingId);
      if (!ref.mounted) return;
      final saved = await _cache.load(listingId);
      if (!ref.mounted) return;
      if (saved != null && saved.key == _cacheKey && _restore(saved)) return;
    }
    state = const PropertyReportState(loading: true);
    try {
      final found = await _repo.resolve(query);
      if (!ref.mounted) return;
      if (found.isEmpty) {
        state = const PropertyReportState(
          error:
              'No property found for this address. Check the street '
              'number, street and suburb. Full reports cover Cape Town and '
              'Johannesburg; in Tshwane, Mossel Bay, Paarl and elsewhere, use "Detect my '
              'address" on the Address screen to find the erf from your '
              'location.',
        );
      } else if (found.length == 1) {
        await open(found.single);
      } else {
        state = PropertyReportState(candidates: found);
      }
    } catch (e) {
      if (ref.mounted) state = PropertyReportState(error: _message(e));
    }
  }

  Future<void> open(PropertyCandidate candidate) async {
    _candidate = candidate;
    state = const PropertyReportState(loading: true);
    try {
      final json = await _repo.fetchReportJson(candidate);
      // Carried to the floor area on the listing, when the agent captured one.
      final report = PropertyReport.fromJson(
        json,
      ).forListingFloorArea(_hints.floorM2);
      final map = report.areaMapUrl;
      final results = await Future.wait([
        _repo.fetchSitePlan(report.sitePlanUrl),
        _marketJson(report.suburb, report.lat, report.lng),
        // Sized for the PDF's page width (the block view sits beside the plan).
        _repo.fetchSitePlan(map == null ? '' : '$map&width=900&height=820'),
        _repo.fetchSitePlan(
          map == null ? '' : '$map&mode=block&width=900&height=640',
        ),
        for (final i in report.imagery) _repo.fetchImage(i.url),
      ]);
      if (!ref.mounted) return;
      final marketJson = results[1] as List<dynamic>;
      final now = DateTime.now();
      state = PropertyReportState(
        report: report,
        sitePlanSvg: results[0] as String?,
        market: _parseMarket(marketJson),
        areaMapSvg: results[2] as String?,
        blockMapSvg: results[3] as String?,
        images: {
          for (var i = 0; i < report.imagery.length; i++)
            if (results[i + 4] case final Uint8List bytes)
              report.imagery[i].url: bytes,
        },
        generatedAt: now,
      );
      _snapshot = ReportSnapshot(
        key: _cacheKey ?? '',
        hintsKey: _hints.key,
        generatedAt: now,
        candidate: candidate.toJson(),
        report: json,
        sitePlanSvg: results[0] as String?,
        areaMapSvg: results[2] as String?,
        blockMapSvg: results[3] as String?,
        market: marketJson,
      );
      await _save();
    } catch (e) {
      if (ref.mounted) state = PropertyReportState(error: _message(e));
      return;
    }
    // The report shows at once; area details and homes for sale follow.
    await Future.wait([_loadArea(), loadForSale()]);
  }

  Future<void> _loadArea() async {
    final report = state.report;
    if (report?.lat == null || report?.lng == null) return;
    try {
      final json = await _repo.fetchAreaJson(report!.lat!, report.lng!);
      if (ref.mounted && state.report == report) {
        state = state.copyWith(area: AreaDetails.fromJson(json));
        _snapshot = _snapshot?.copyWith(area: json);
        await _save();
      }
    } catch (e) {
      developer.log('Area details failed: $e');
    }
  }

  /// Similar homes on Property24; [p24Suburb] searches another of the
  /// Property24 suburbs offered.
  Future<void> loadForSale({int? p24Suburb}) async {
    final report = state.report;
    if (report == null) return;
    try {
      final json = await _repo.fetchForSaleJson(
        report,
        bedrooms: _hints.bedrooms,
        floorM2: _hints.floorM2 ?? report.dwellingExtentM2,
        erfM2: _hints.erfM2 ?? report.extentM2,
        p24Suburb: p24Suburb,
        priceZar: report.bestRange?.mid ?? report.municipalValueZar,
      );
      if (ref.mounted && state.report == report) {
        state = state.copyWith(forSale: ForSale.fromJson(json));
        _snapshot = _snapshot?.copyWith(forSale: json, hintsKey: _hints.key);
        await _save();
      }
    } catch (e) {
      developer.log('Homes for sale failed: $e');
    }
  }

  /// The agency's listings nearby are extras: failing to load them never
  /// costs the agent the report.
  Future<List<dynamic>> _marketJson(
    String suburb,
    double? lat,
    double? lng,
  ) async {
    try {
      return await _repo.fetchMarketJson(
        suburb,
        excludeListingId: _listingId,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      developer.log('Agency listings nearby failed: $e');
      return const [];
    }
  }

  /// Logs a sale in this report's suburb and reloads the report so it shows
  /// (the municipal part comes from the API's cache, so this is quick).
  /// Returns true when another agent had already logged the same sale.
  Future<bool> addAgentSale(NewAgentSale sale) async {
    final duplicate = await _repo.addAgentSale(sale);
    await _reloadReport();
    return duplicate;
  }

  Future<void> deleteAgentSale(String id) async {
    await _repo.deleteAgentSale(id);
    await _reloadReport();
  }

  Future<void> _reloadReport() async {
    final candidate = _candidate;
    if (candidate == null) return;
    final json = await _repo.fetchReportJson(candidate);
    final report = PropertyReport.fromJson(
      json,
    ).forListingFloorArea(_hints.floorM2);
    if (!ref.mounted) return;
    state = state.copyWith(report: report);
    _snapshot = _snapshot?.copyWith(report: json);
    await _save();
  }

  /// Shows a saved report, as it was; false when it cannot be read.
  bool _restore(ReportSnapshot saved) {
    try {
      final candidate = PropertyCandidate.fromJson(saved.candidate);
      final report = PropertyReport.fromJson(
        saved.report,
      ).forListingFloorArea(_hints.floorM2);
      _candidate = candidate;
      _snapshot = saved;
      state = PropertyReportState(
        report: report,
        sitePlanSvg: saved.sitePlanSvg,
        areaMapSvg: saved.areaMapSvg,
        blockMapSvg: saved.blockMapSvg,
        market: _parseMarket(saved.market),
        area: saved.area == null ? null : AreaDetails.fromJson(saved.area!),
        forSale: saved.forSale == null
            ? null
            : ForSale.fromJson(saved.forSale!),
        generatedAt: saved.generatedAt,
      );
    } catch (e) {
      developer.log('Saved report could not be shown: $e');
      return false;
    }
    // Imagery is never kept (Google's terms), so it is fetched again.
    _loadImagery();
    // Only what the listing changed since is looked up again: homes for sale
    // follow its bedrooms and sizes. Rooms, conditions, photos, owners and
    // the agent's figures are never kept here; the PDF reads them from the
    // listing each time. Homes for sale are also looked up again when there
    // were none to keep (Property24 was down, e.g. for maintenance).
    if (saved.hintsKey != _hints.key || saved.forSale == null) loadForSale();
    return true;
  }

  Future<void> _loadImagery() async {
    final report = state.report;
    if (report == null || report.imagery.isEmpty) return;
    final images = <String, Uint8List>{};
    for (final i in report.imagery) {
      if (await _repo.fetchImage(i.url) case final bytes?) {
        images[i.url] = bytes;
      }
    }
    if (!ref.mounted || state.report != report || images.isEmpty) return;
    state = PropertyReportState(
      report: state.report,
      sitePlanSvg: state.sitePlanSvg,
      areaMapSvg: state.areaMapSvg,
      blockMapSvg: state.blockMapSvg,
      images: images,
      market: state.market,
      area: state.area,
      forSale: state.forSale,
      generatedAt: state.generatedAt,
    );
  }

  Future<void> _save() async {
    final id = _listingId, snapshot = _snapshot;
    if (id != null && snapshot != null) await _cache.save(id, snapshot);
  }

  static List<MarketListing> _parseMarket(List<dynamic> json) => [
    for (final e in json) MarketListing.fromJson(e as Map<String, dynamic>),
  ];

  static String _message(Object e) {
    if (e is DioException && e.response?.statusCode == 502) {
      return "The municipality's property services did not respond. "
          'Try again in a few minutes.';
    }
    if (e is DioException && e.response?.statusCode == 404) {
      return 'That property was not found in the municipal records.';
    }
    return mapFailure(e).message;
  }
}

final propertyReportProvider =
    NotifierProvider.autoDispose<PropertyReportNotifier, PropertyReportState>(
      PropertyReportNotifier.new,
    );

/// What the agent captured about the home, for finding similar homes.
class ListingHints {
  final int? bedrooms;
  final double? floorM2;
  final double? erfM2;
  const ListingHints({this.bedrooms, this.floorM2, this.erfM2});

  /// Changes when any of them does.
  String get key => '${bedrooms ?? ''}|${floorM2 ?? ''}|${erfM2 ?? ''}';
}
