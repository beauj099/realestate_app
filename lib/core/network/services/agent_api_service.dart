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
}
