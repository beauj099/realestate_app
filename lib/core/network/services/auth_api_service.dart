import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/auth_dtos.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService(this._client);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
