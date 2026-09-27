import 'package:dio/dio.dart';

import '../api_client.dart';
import '../api_endpoints.dart';

/// The signed-in agent's own profile. The API resolves "me" from the JWT.
class AgentApiService {
  final ApiClient _client;

  AgentApiService(this._client);

  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get(ApiEndpoints.agentMe);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final response = await _client.put(ApiEndpoints.agentMe, data: body);
    return response.data as Map<String, dynamic>;
  }

  /// Profile photo (PNG or JPEG). Returns the updated profile.
  Future<Map<String, dynamic>> uploadPhoto(String path) =>
      _putImage(ApiEndpoints.agentPhoto, path);

  /// Signature for the valuation letter (PNG or JPEG).
  Future<Map<String, dynamic>> uploadSignature(String path) =>
      _putImage(ApiEndpoints.agentSignature, path);

  /// Appends brochure pages to the agent's own set.
  Future<Map<String, dynamic>> addBrochurePages(List<String> paths) async {
    final form = FormData.fromMap({
      'pages': [
        for (final (i, p) in paths.indexed)
          await MultipartFile.fromFile(p, filename: 'page$i${_extension(p)}'),
      ],
    });
    final response = await _client.post(
      ApiEndpoints.agentBrochurePages,
      data: form,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Keeps these of the agent's pages, in this order; null goes back to the
  /// agency's pages.
  Future<Map<String, dynamic>> setBrochurePages(List<String>? keep) async {
    final response = await _client.put(
      ApiEndpoints.agentBrochurePages,
      data: keep,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setReportSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _client.put(
      ApiEndpoints.agentReportSettings,
      data: settings,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _putImage(String endpoint, String path) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        path,
        filename: 'image${_extension(path)}',
      ),
    });
    final response = await _client.put(endpoint, data: form);
    return response.data as Map<String, dynamic>;
  }

  /// The API takes .png, .jpg and .jpeg; anything else is sent as .jpg (the
  /// image picker re-encodes to JPEG).
  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot).toLowerCase();
    return const {'.png', '.jpg', '.jpeg'}.contains(ext) ? ext : '.jpg';
  }
}
