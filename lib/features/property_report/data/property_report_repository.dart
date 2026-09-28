import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/address_suggestion.dart';
import 'models/agent_sales.dart';
import 'models/area_details.dart';
import 'models/property_report.dart';

/// What to look a property up by. The API prefers a coordinate (point in the
/// cadastre polygon), then the erf number, then the street address.
class ReportQuery {
  final String address;
  final String? erf;
  final String? suburb;
  final double? lat;
  final double? lng;

  const ReportQuery({
    required this.address,
    this.erf,
    this.suburb,
    this.lat,
    this.lng,
  });
}

/// Talks to the property report endpoints (`/api/property/...`).
class PropertyReportRepository {
  final ApiClient _client;

  PropertyReportRepository(this._client);

  /// The first report for a property reads several City services (cadastre,
  /// valuation roll, area sales) and can take 10–30 seconds; repeats come
  /// from the API's cache.
  static const Duration _reportTimeout = Duration(seconds: 90);

  /// Addresses matching what the agent has typed so far. [national] false
  /// asks the Cape Town and Johannesburg parcel records (fast); true asks
  /// OpenStreetMap for the whole country (a few seconds). [lat]/[lng] favour
  /// places nearby. Fewer than 3 characters returns nothing.
  Future<List<AddressSuggestion>> suggest(
    String text, {
    bool national = false,
    double? lat,
    double? lng,
  }) async {
    if (text.trim().length < 3) return const [];
    final response = await _client.get(
      national
          ? ApiEndpoints.propertySuggestNational
          : ApiEndpoints.propertySuggest,
      queryParameters: {
        'q': text.trim(),
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
      },
      receiveTimeout: national ? const Duration(seconds: 15) : null,
    );
    return [
      for (final e in response.data as List)
        AddressSuggestion.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// The City's address at a GPS point (Cape Town, Johannesburg): the erf
  /// under the pin first, then its neighbours, with the house number and the
  /// City's official suburb. Empty elsewhere.
  Future<List<AddressSuggestion>> addressAt(double lat, double lng) async {
    final response = await _client.get(
      ApiEndpoints.propertySuggestAt,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return [
      for (final e in response.data as List)
        AddressSuggestion.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<List<PropertyCandidate>> resolve(ReportQuery q) async {
    // Most precise first; a miss (e.g. GPS a little off the erf, or a listing
    // without coordinates) falls through to the next.
    final attempts = <Map<String, dynamic>>[
      if (q.lat != null && q.lng != null) {'lat': q.lat, 'lng': q.lng},
      if ((q.erf ?? '').trim().isNotEmpty)
        {'erf': q.erf!.trim(), 'suburb': q.suburb?.trim().toUpperCase()},
      if (q.address.trim().isNotEmpty) {'address': q.address.trim()},
    ];
    for (final body in attempts) {
      final response = await _client.post(
        ApiEndpoints.propertyResolve,
        data: body,
      );
      final found = [
        for (final e in response.data as List)
          PropertyCandidate.fromJson(e as Map<String, dynamic>),
      ];
      if (found.isNotEmpty) return found;
    }
    return const [];
  }

  Future<PropertyReport> fetchReport(PropertyCandidate c) async {
    final response = await _client.get(
      ApiEndpoints.propertyReport(c.municipality, c.erf),
      queryParameters: {
        'suburb': c.suburb,
        'sg26': ?c.sg26,
        'includeComparables': true,
      },
      receiveTimeout: _reportTimeout,
    );
    return PropertyReport.fromJson(response.data as Map<String, dynamic>);
  }

  /// Logs a sale the agent knows about. Returns true when another agent had
  /// already logged it (it then counts as confirmation instead of a new sale).
  Future<bool> addAgentSale(NewAgentSale sale) async {
    final response = await _client.post(
      ApiEndpoints.comparables,
      data: sale.toJson(),
    );
    final data = response.data;
    return data is Map && data['wasDuplicate'] == true;
  }

  Future<void> deleteAgentSale(String id) =>
      _client.delete(ApiEndpoints.comparable(id));

  /// The agency's own listings in [suburb], except [excludeListingId].
  Future<List<MarketListing>> fetchMarket(
    String suburb, {
    int? excludeListingId,
    double? lat,
    double? lng,
  }) async {
    if (suburb.trim().isEmpty) return const [];
    final response = await _client.get(
      ApiEndpoints.comparablesMarket,
      queryParameters: {
        'suburb': suburb.trim(),
        'excludeListingId': ?excludeListingId,
        'lat': ?lat,
        'lng': ?lng,
      },
    );
    return [
      for (final e in response.data as List)
        MarketListing.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// Climate, population, household income and crime around a point.
  Future<AreaDetails> fetchArea(double lat, double lng) async {
    final response = await _client.get(
      ApiEndpoints.propertyArea,
      queryParameters: {'lat': lat, 'lng': lng},
      receiveTimeout: _reportTimeout,
    );
    return AreaDetails.fromJson(response.data as Map<String, dynamic>);
  }

  /// Homes for sale like this one on Property24. [p24Suburb] picks a
  /// Property24 suburb other than the ones matched to the report's.
  Future<ForSale> fetchForSale(
    PropertyReport report, {
    int? bedrooms,
    double? floorM2,
    double? erfM2,
    int? p24Suburb,
    int max = 3,
  }) async {
    final response = await _client.get(
      ApiEndpoints.propertyForSale(report.municipality, report.erf),
      queryParameters: {
        'suburb': report.suburb,
        'township': report.township,
        'p24Suburb': ?p24Suburb,
        'bedrooms': ?bedrooms,
        'floorM2': ?floorM2,
        'erfM2': ?erfM2,
        'max': max,
        // With the property's location the nearest homes are kept, whatever
        // suburb Property24 files them under.
        'lat': ?report.lat,
        'lng': ?report.lng,
      },
      receiveTimeout: _reportTimeout,
    );
    return ForSale.fromJson(response.data as Map<String, dynamic>);
  }

  /// The site plan SVG, or null when it cannot be drawn.
  Future<String?> fetchSitePlan(String sitePlanUrl) async {
    if (sitePlanUrl.isEmpty) return null;
    try {
      final response = await _client.get<String>(
        sitePlanUrl,
        responseType: ResponseType.plain,
        receiveTimeout: _reportTimeout,
      );
      return response.data;
    } catch (e) {
      developer.log('Site plan failed: $e');
      return null;
    }
  }

  /// Imagery bytes through our API's proxy (which holds the Google key). Null
  /// when there is none, e.g. no Street View panorama at the address.
  Future<Uint8List?> fetchImage(String url) async {
    try {
      final response = await _client.get<List<int>>(
        url,
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 30),
      );
      final data = response.data;
      return data == null ? null : Uint8List.fromList(data);
    } catch (e) {
      developer.log('Imagery failed ($url): $e');
      return null;
    }
  }
}
