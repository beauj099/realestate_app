import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/address_suggestion.dart';
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

  /// Addresses matching what the agent has typed so far (Cape Town parcel
  /// records). Fewer than 3 characters returns nothing.
  Future<List<AddressSuggestion>> suggest(String text) async {
    if (text.trim().length < 3) return const [];
    final response = await _client.get(
      ApiEndpoints.propertySuggest,
      queryParameters: {'q': text.trim()},
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
      queryParameters: {'suburb': c.suburb, 'includeComparables': true},
      receiveTimeout: _reportTimeout,
    );
    return PropertyReport.fromJson(response.data as Map<String, dynamic>);
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
