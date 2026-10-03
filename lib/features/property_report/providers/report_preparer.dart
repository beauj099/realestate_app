import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../property_overview/data/models/enums/room_category.dart';
import '../../property_overview/data/models/property_state.dart';
import '../data/models/area_details.dart';
import '../data/models/property_report.dart';
import '../data/property_report_repository.dart';
import '../data/report_cache.dart';
import '../../property_overview/providers/property_provider.dart';
import 'city_records_autofill.dart';
import 'property_report_provider.dart';

/// The listing's own details a saved report is filed under: its address,
/// erf and pin. The same everywhere a report is made or looked for.
String reportKeyForListing(PropertyState l) => ReportSnapshot.keyFor(
  ReportQuery(
    address: [
      '${l.streetNumber} ${l.street}'.trim(),
      l.suburb.trim(),
      l.city.trim(),
    ].where((p) => p.isNotEmpty).join(', '),
    erf: l.erfNumber,
    lat: l.latitude,
    lng: l.longitude,
  ),
);

/// What the listing says about the home, for its floor area and for homes
/// for sale like it.
ListingHints reportHintsForListing(PropertyState l) {
  final bedrooms = l.rooms
      .where(
        (r) =>
            RoomCategoryExtension.categoryForRoomTypeId(r.roomTypeId) ==
            RoomCategory.bedroom,
      )
      .length;
  return ListingHints(
    bedrooms: bedrooms == 0 ? null : bedrooms,
    floorM2: double.tryParse(l.floorArea.replaceAll(',', '.')),
    erfM2: double.tryParse(l.erfSize.replaceAll(',', '.')),
  );
}

/// Makes a listing's valuation report in the background once its address is
/// saved, and keeps it on the phone ([ReportCache]), so the report screen
/// opens it at once instead of starting from scratch. The report screen
/// waits for one still being made ([running]) rather than making another.
class ReportPreparer {
  ReportPreparer(this._ref);

  final Ref _ref;
  final _running = <int, Future<void>>{};

  PropertyReportRepository get _repo =>
      _ref.read(propertyReportRepositoryProvider);
  ReportCache get _cache => _ref.read(reportCacheProvider);

  /// The report being made for [listingId], if one is.
  Future<void>? running(int listingId) => _running[listingId];

  /// Starts making [listing]'s report, unless one for its current address,
  /// erf and pin is already kept or on its way.
  void prepare(PropertyState listing) {
    final id = listing.listingId;
    if (id == null || _running.containsKey(id)) return;
    if (listing.street.trim().isEmpty &&
        listing.erfNumber.trim().isEmpty &&
        listing.latitude == null) {
      return;
    }
    _running[id] = _make(id, listing).whenComplete(() => _running.remove(id));
  }

  Future<void> _make(int id, PropertyState listing) async {
    final key = reportKeyForListing(listing);
    final hints = reportHintsForListing(listing);
    try {
      if ((await _cache.load(id))?.key == key) return;
      final found = await _repo.resolve(
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
      // Several matches: the agent picks one on the report screen.
      if (found.length != 1) return;
      final candidate = found.single;
      final json = await _repo.fetchReportJson(candidate);
      final report = PropertyReport.fromJson(
        json,
      ).forListingFloorArea(hints.floorM2);
      final map = report.areaMapUrl;
      final lat = report.lat, lng = report.lng;
      final results = await Future.wait<Object?>([
        _repo.fetchSitePlan(report.sitePlanUrl),
        _extra(
          () => _repo.fetchMarketJson(
            report.suburb,
            excludeListingId: id,
            lat: lat,
            lng: lng,
          ),
        ),
        _repo.fetchSitePlan(map == null ? '' : '$map&width=900&height=820'),
        _repo.fetchSitePlan(
          map == null ? '' : '$map&mode=block&width=900&height=640',
        ),
        if (lat != null && lng != null)
          _extra(() => _repo.fetchAreaJson(lat, lng))
        else
          Future.value(null),
        _extra(
          () => _repo.fetchForSaleJson(
            report,
            bedrooms: hints.bedrooms,
            floorM2: hints.floorM2 ?? report.dwellingExtentM2,
            erfM2: hints.erfM2 ?? report.extentM2,
            priceZar: report.bestRange?.mid ?? report.municipalValueZar,
          ),
        ),
      ]);
      await _cache.save(
        id,
        ReportSnapshot(
          key: key,
          hintsKey: hints.key,
          generatedAt: DateTime.now(),
          candidate: candidate.toJson(),
          report: json,
          sitePlanSvg: results[0] as String?,
          market: results[1] as List<dynamic>? ?? const [],
          areaMapSvg: results[2] as String?,
          blockMapSvg: results[3] as String?,
          area: results[4] as Map<String, dynamic>?,
          forSale: results[5] as Map<String, dynamic>?,
        ),
      );
      // The full report has what the quick lookup may not (Cape Town's last
      // registered sale): fill the listing's empty fields from it, while it
      // is still the listing open.
      if (_ref.read(propertyViewModelProvider).listingId == id) {
        final autofill = _ref.read(cityRecordsAutofillProvider.notifier);
        await autofill.apply(report);
        if (results[5] case final Map<String, dynamic> forSale) {
          await autofill.applyMarketingArea(ForSale.fromJson(forSale));
        }
      }
    } catch (e) {
      // The report screen makes it then, as before.
      developer.log('Report not prepared in the background: $e');
    }
  }

  /// Extras (agency listings, area details, homes for sale) never cost the
  /// report.
  static Future<T?> _extra<T>(Future<T> Function() load) async {
    try {
      return await load();
    } catch (e) {
      developer.log('Report extra skipped: $e');
      return null;
    }
  }
}

final reportPreparerProvider = Provider<ReportPreparer>(ReportPreparer.new);

/// The report kept on the phone for [listing], if it was made for the
/// listing's current address; null when there is none yet. For screens that
/// start from the report's figures (Price & Commission, Purchase History).
Future<PropertyReport?> savedReportFor(
  ReportCache cache,
  PropertyState listing,
) async {
  final id = listing.listingId;
  if (id == null) return null;
  final saved = await cache.load(id);
  if (saved == null || saved.key != reportKeyForListing(listing)) return null;
  try {
    return PropertyReport.fromJson(
      saved.report,
    ).forListingFloorArea(reportHintsForListing(listing).floorM2);
  } catch (e) {
    developer.log('Saved report unreadable: $e');
    return null;
  }
}
