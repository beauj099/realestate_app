import 'package:dio/dio.dart';

import '../../../features/property_overview/data/models/nominatim_result.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'realworth_property_evaluation_app';

  final Dio _dio;

  NominatimService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'User-Agent': _userAgent, 'Accept-Language': 'en'},
            ),
          );

  Future<List<NominatimResult>> searchAddress(String query) async {
    final sanitized = query.trim();
    if (sanitized.isEmpty) return const [];

    final response = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {
        'q': sanitized,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': 8,
        'countrycodes': 'za',
      },
    );

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NominatimResult.fromJson)
        .toList();
  }
}
