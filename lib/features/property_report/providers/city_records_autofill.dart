import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../property_overview/data/models/property_state.dart';
import '../../property_overview/providers/property_provider.dart';
import '../data/models/property_report.dart';
import '../data/property_report_repository.dart';
import 'property_report_provider.dart';

/// Maps a municipal zoning (Cape Town codes, Johannesburg names) to the app's five zoning chips (ids 1–5 in
/// Building Info). Null when it is none of them (e.g. open space, utility).
int? zoningIdFor(String? code, String? description) {
  final c = (code ?? '').toUpperCase();
  final d = (description ?? '').toLowerCase();
  bool any(List<String> codes, List<String> words) =>
      codes.any(c.startsWith) || words.any(d.contains);

  return switch (true) {
    _ when any(['SR'], ['single residential', 'residential 1']) => 1,
    _ when any(['GR'], ['general residential', 'residential 2']) => 2,
    _ when any(['MU'], ['mixed use']) => 5,
    _ when any(['LB', 'GB'], ['business', 'commercial']) => 3,
    _ when any(['AG'], ['agricultur']) => 4,
    _ => null,
  };
}

/// What the City's records can fill in on a listing: only fields that are
/// still empty. Nothing the agent typed is ever overwritten.
class AutofillPlan {
  final String? erfNumber;
  final double? latitude;
  final double? longitude;
  final String? erfSize;
  final String? floorArea;
  final int? zoningId;

  /// Human-readable list of what was filled, for the confirmation.
  final List<String> filled;

  const AutofillPlan({
    this.erfNumber,
    this.latitude,
    this.longitude,
    this.erfSize,
    this.floorArea,
    this.zoningId,
    this.filled = const [],
  });

  bool get isEmpty => filled.isEmpty && latitude == null;
  bool get touchesAddress => erfNumber != null || latitude != null;
  bool get touchesBuildingInfo =>
      erfSize != null || floorArea != null || zoningId != null;
}

const _zoningNames = {
  1: 'Residential 1',
  2: 'Residential 2',
  3: 'Commercial',
  4: 'Agricultural',
  5: 'Mixed Use',
};

AutofillPlan planAutofill(PropertyState s, PropertyReport r) {
  bool blank(String v) => v.trim().isEmpty;
  final filled = <String>[];

  final erf = blank(s.erfNumber) && r.erf.isNotEmpty ? r.erf : null;
  if (erf != null) filled.add('erf number $erf');

  final hasPin = s.latitude != null && s.longitude != null;
  final lat = !hasPin ? r.lat : null;
  final lng = !hasPin ? r.lng : null;

  final extent = r.extentM2;
  final erfSize = blank(s.erfSize) && extent != null
      ? extent.round().toString()
      : null;
  if (erfSize != null) filled.add('erf size ${groupDigits(extent!)} m²');

  // The City's own record of building size; the roof area is a stand-in.
  final building = r.dwellingExtentM2 ?? r.totalRoofM2;
  final floorArea = blank(s.floorArea) && building != null
      ? building.round().toString()
      : null;
  if (floorArea != null) {
    filled.add(
      '${r.dwellingExtentM2 != null ? 'floor area' : 'floor area (roof footprint)'} '
      '${groupDigits(building!)} m²',
    );
  }

  final zoning = s.zoningId == null
      ? zoningIdFor(r.zoningCode, r.zoningDescription)
      : null;
  if (zoning != null) filled.add('zoning (${_zoningNames[zoning]})');

  return AutofillPlan(
    erfNumber: erf,
    latitude: lat,
    longitude: lng,
    erfSize: erfSize,
    floorArea: floorArea,
    zoningId: zoning,
    filled: filled,
  );
}

class CityRecordsAutofillState {
  final bool running;

  /// What was filled in, for a one-off confirmation; null once shown.
  final String? message;

  const CityRecordsAutofillState({this.running = false, this.message});
}

/// Fills a listing's empty fields (erf number, erf size, floor area, zoning,
/// location) from municipal records (Cape Town, Johannesburg, or the national cadastre),
/// and saves them.
///
/// Runs after the address is saved, in the background: the City can take
/// 10–30 seconds, and the agent should not wait for it. Kept alive so it
/// finishes after the address screen closes; it also warms the API's cache,
/// so the valuation report opens instantly afterwards.
class CityRecordsAutofill extends Notifier<CityRecordsAutofillState> {
  @override
  CityRecordsAutofillState build() => const CityRecordsAutofillState();

  static bool needsFilling(PropertyState s) =>
      s.erfNumber.trim().isEmpty ||
      s.erfSize.trim().isEmpty ||
      s.floorArea.trim().isEmpty ||
      s.zoningId == null ||
      s.latitude == null;

  /// Looks the listing up and fills what is missing. Silent when the
  /// property is not covered, the address is ambiguous, or the source is
  /// unreachable: this is a convenience, never a blocker.
  Future<void> fillMissing() async {
    final listing = ref.read(propertyViewModelProvider);
    final listingId = listing.listingId;
    if (listingId == null || !needsFilling(listing) || state.running) return;
    if (listing.street.trim().isEmpty &&
        listing.erfNumber.trim().isEmpty &&
        listing.latitude == null) {
      return;
    }

    state = const CityRecordsAutofillState(running: true);
    try {
      final repo = ref.read(propertyReportRepositoryProvider);
      final found = await repo.resolve(
        ReportQuery(
          address: [
            '${listing.streetNumber} ${listing.street}'.trim(),
            listing.suburb.trim(),
          ].where((p) => p.isNotEmpty).join(', '),
          erf: listing.erfNumber,
          suburb: listing.suburb,
          lat: listing.latitude,
          lng: listing.longitude,
        ),
      );
      if (found.length != 1) {
        state = const CityRecordsAutofillState();
        return;
      }
      final report = await repo.fetchReport(found.single);
      // The agent may have moved to another listing meanwhile.
      if (ref.read(propertyViewModelProvider).listingId != listingId) {
        state = const CityRecordsAutofillState();
        return;
      }
      await apply(report);
    } catch (e) {
      developer.log('City records autofill skipped: $e');
      state = const CityRecordsAutofillState();
    }
  }

  /// Applies [report] to the open listing's empty fields and saves them.
  /// Returns what was filled, or null when there was nothing to fill.
  Future<String?> apply(PropertyReport report) async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final plan = planAutofill(ref.read(propertyViewModelProvider), report);
    if (plan.isEmpty) {
      state = const CityRecordsAutofillState();
      return null;
    }

    if (plan.erfNumber != null) {
      viewModel.updateIdentifiers(erfNumber: plan.erfNumber);
    }
    if (plan.latitude != null) {
      viewModel.updateCoordinates(
        latitude: plan.latitude,
        longitude: plan.longitude,
      );
    }
    if (plan.erfSize != null || plan.floorArea != null) {
      viewModel.updateTechnicalSpecs(
        erfSize: plan.erfSize,
        floorArea: plan.floorArea,
      );
    }
    if (plan.zoningId != null) viewModel.selectZoningId(plan.zoningId);

    if (plan.touchesAddress) await viewModel.saveAddress();
    if (plan.touchesBuildingInfo) await viewModel.saveBuildingInfo();

    final message = plan.filled.isEmpty
        ? null
        : 'Filled in from ${report.dataSource}: ${plan.filled.join(', ')}.';
    state = CityRecordsAutofillState(message: message);
    return message;
  }

  void clearMessage() => state = const CityRecordsAutofillState();
}

final cityRecordsAutofillProvider =
    NotifierProvider<CityRecordsAutofill, CityRecordsAutofillState>(
      CityRecordsAutofill.new,
    );
