import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/providers/api_providers.dart';
import '../data/models/agent_sales.dart';
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

  /// Imagery bytes keyed by [ImageryRef.url]. Held in memory only — Google's
  /// terms forbid storing them.
  final Map<String, Uint8List> images;

  /// The agency's own listings in the suburb ("on the market nearby").
  final List<MarketListing> market;

  const PropertyReportState({
    this.loading = false,
    this.error,
    this.candidates = const [],
    this.report,
    this.sitePlanSvg,
    this.images = const {},
    this.market = const [],
  });

  PropertyReportState copyWith({
    PropertyReport? report,
    List<MarketListing>? market,
  }) => PropertyReportState(
    loading: loading,
    error: error,
    candidates: candidates,
    report: report ?? this.report,
    sitePlanSvg: sitePlanSvg,
    images: images,
    market: market ?? this.market,
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

  Future<void> lookUp(ReportQuery query, {int? listingId}) async {
    _listingId = listingId;
    state = const PropertyReportState(loading: true);
    try {
      final found = await _repo.resolve(query);
      if (!ref.mounted) return;
      if (found.isEmpty) {
        state = const PropertyReportState(
          error:
              'No property found for this address. Check the street '
              'number, street and suburb. Full reports cover Cape Town and '
              'Johannesburg; elsewhere, use "Detect my address" on the '
              'Address screen to find the erf from your location.',
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
      final report = await _repo.fetchReport(candidate);
      final results = await Future.wait([
        _repo.fetchSitePlan(report.sitePlanUrl),
        _market(report.suburb),
        for (final i in report.imagery) _repo.fetchImage(i.url),
      ]);
      if (!ref.mounted) return;
      state = PropertyReportState(
        report: report,
        sitePlanSvg: results[0] as String?,
        market: results[1] as List<MarketListing>,
        images: {
          for (var i = 0; i < report.imagery.length; i++)
            if (results[i + 2] case final Uint8List bytes)
              report.imagery[i].url: bytes,
        },
      );
    } catch (e) {
      if (ref.mounted) state = PropertyReportState(error: _message(e));
    }
  }

  /// The agency's listings nearby are extras: failing to load them never
  /// costs the agent the report.
  Future<List<MarketListing>> _market(String suburb) async {
    try {
      return await _repo.fetchMarket(suburb, excludeListingId: _listingId);
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
    final report = await _repo.fetchReport(candidate);
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
