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

  Future<NominatimResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': 1,
      },
    );

    final data = response.data;
    if (data == null || data.containsKey('error')) return null;
    return NominatimResult.fromJson(data);
  }
}