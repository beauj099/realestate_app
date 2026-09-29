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

final propertyReportRepositoryProvider = Provider<PropertyReportRepository>(
  (ref) => PropertyReportRepository(ref.watch(apiClientProvider)),
);

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
  );
}

/// Loads a valuation report for one property: resolve the address to an erf,
/// then fetch the report, its site plan and imagery.
class PropertyReportNotifier extends Notifier<PropertyReportState> {
  @override
  PropertyReportState build() => const PropertyReportState();

  PropertyReportRepository get _repo =>
      ref.read(propertyReportRepositoryProvider);

  PropertyCandidate? _candidate;

  /// The listing the report is for, left out of the agency's listings nearby.
  int? _listingId;

  /// What the listing says about the home, to find similar homes for sale.
  ListingHints _hints = const ListingHints();

  Future<void> lookUp(
    ReportQuery query, {
    int? listingId,
    ListingHints hints = const ListingHints(),
  }) async {
    _listingId = listingId;
    _hints = hints;
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
      // Carried to the floor area on the listing, when the agent captured one.
      final report = (await _repo.fetchReport(
        candidate,
      )).forListingFloorArea(_hints.floorM2);
      final map = report.areaMapUrl;
      final results = await Future.wait([
        _repo.fetchSitePlan(report.sitePlanUrl),
        _market(report.suburb, report.lat, report.lng),
        // Sized for the PDF's page width (the block view sits beside the plan).
        _repo.fetchSitePlan(map == null ? '' : '$map&width=900&height=820'),
        _repo.fetchSitePlan(
          map == null ? '' : '$map&mode=block&width=900&height=640',
        ),
        for (final i in report.imagery) _repo.fetchImage(i.url),
      ]);
      if (!ref.mounted) return;
      state = PropertyReportState(
        report: report,
        sitePlanSvg: results[0] as String?,
        market: results[1] as List<MarketListing>,
        areaMapSvg: results[2] as String?,
        blockMapSvg: results[3] as String?,
        images: {
          for (var i = 0; i < report.imagery.length; i++)
            if (results[i + 4] case final Uint8List bytes)
              report.imagery[i].url: bytes,
        },
      );
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
      final area = await _repo.fetchArea(report!.lat!, report.lng!);
      if (ref.mounted && state.report == report) {
        state = state.copyWith(area: area);
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
      final forSale = await _repo.fetchForSale(
        report,
        bedrooms: _hints.bedrooms,
        floorM2: _hints.floorM2 ?? report.dwellingExtentM2,
        erfM2: _hints.erfM2 ?? report.extentM2,
        p24Suburb: p24Suburb,
        priceZar: report.bestRange?.mid ?? report.municipalValueZar,
      );
      if (ref.mounted && state.report == report) {
        state = state.copyWith(forSale: forSale);
      }
    } catch (e) {
      developer.log('Homes for sale failed: $e');
    }
  }

  /// The agency's listings nearby are extras: failing to load them never
  /// costs the agent the report.
  Future<List<MarketListing>> _market(
    String suburb,
    double? lat,
    double? lng,
  ) async {
    try {
      return await _repo.fetchMarket(
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
    final report = (await _repo.fetchReport(
      candidate,
    )).forListingFloorArea(_hints.floorM2);
    if (ref.mounted) state = state.copyWith(report: report);
  }

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
}
