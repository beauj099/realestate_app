import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/providers/api_providers.dart';
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

  const PropertyReportState({
    this.loading = false,
    this.error,
    this.candidates = const [],
    this.report,
    this.sitePlanSvg,
    this.images = const {},
  });
}

/// Loads a valuation report for one property: resolve the address to an erf,
/// then fetch the report, its site plan and imagery.
class PropertyReportNotifier extends Notifier<PropertyReportState> {
  @override
  PropertyReportState build() => const PropertyReportState();

  PropertyReportRepository get _repo =>
      ref.read(propertyReportRepositoryProvider);

  Future<void> lookUp(ReportQuery query) async {
    state = const PropertyReportState(loading: true);
    try {
      final found = await _repo.resolve(query);
      if (!ref.mounted) return;
      if (found.isEmpty) {
        state = const PropertyReportState(
          error:
              'No Cape Town property found for this address. Check the '
              'street number, street and suburb (only City of Cape Town '
              'properties are covered so far).',
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
    state = const PropertyReportState(loading: true);
    try {
      final report = await _repo.fetchReport(candidate);
      final results = await Future.wait([
        _repo.fetchSitePlan(report.sitePlanUrl),
        for (final i in report.imagery) _repo.fetchImage(i.url),
      ]);
      if (!ref.mounted) return;
      state = PropertyReportState(
        report: report,
        sitePlanSvg: results.first as String?,
        images: {
          for (var i = 0; i < report.imagery.length; i++)
            if (results[i + 1] case final Uint8List bytes)
              report.imagery[i].url: bytes,
        },
      );
    } catch (e) {
      if (ref.mounted) state = PropertyReportState(error: _message(e));
    }
  }

  static String _message(Object e) {
    if (e is DioException && e.response?.statusCode == 502) {
      return "The City of Cape Town's property services did not respond. "
          'Try again in a few minutes.';
    }
    if (e is DioException && e.response?.statusCode == 404) {
      return 'That property was not found in the Cape Town records.';
    }
    return mapFailure(e).message;
  }
}

final propertyReportProvider =
    NotifierProvider.autoDispose<PropertyReportNotifier, PropertyReportState>(
      PropertyReportNotifier.new,
    );
