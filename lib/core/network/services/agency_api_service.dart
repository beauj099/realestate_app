import 'package:dio/dio.dart';

import '../api_client.dart';
import '../api_endpoints.dart';

/// White-label agencies. Listing works signed out (registration asks for the
/// agency first); adding one needs a signed-in agent.
class AgencyApiService {
  final ApiClient _client;

  AgencyApiService(this._client);

  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _client.get(ApiEndpoints.agencies);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// Adds an unlisted agency, with its logo when [logoPath] is given. Returns
  /// the new agency, or the existing one with the same name.
  Future<Map<String, dynamic>> add({
    required String name,
    String? logoPath,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      if (logoPath != null)
        'logo': await MultipartFile.fromFile(
          logoPath,
          filename: 'logo${_extension(logoPath)}',
        ),
    });
    final response = await _client.post(ApiEndpoints.agencies, data: form);
    return response.data as Map<String, dynamic>;
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot).toLowerCase();
    return const {'.png', '.jpg', '.jpeg', '.webp'}.contains(ext)
        ? ext
        : '.jpg';
  }
}
