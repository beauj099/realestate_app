import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/auth_dtos.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService(this._client);

  Future<LoginResponse> login(String username, String password) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    final json = response.data as Map<String, dynamic>;
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Future<RefreshTokenResponse> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );
    final json = response.data as Map<String, dynamic>;
    return RefreshTokenResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      refreshToken: json['refreshToken'] as String,
    );
  }

  Future<LoginResponse> register({
    required String fullName,
    required String email,
    required String mobile,
    required String agencyName,
    String? agencyRegistrationNumber,
    String? licenceNumber,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'agencyName': agencyName,
        'agencyRegistrationNumber': _nullIfBlank(agencyRegistrationNumber),
        'licenceNumber': _nullIfBlank(licenceNumber),
        'password': password,
      },
    );
    final json = response.data as Map<String, dynamic>;
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  /// Emails a 6-digit reset code. The API answers 204 whether or not the
  /// address is registered, so this cannot tell the caller which it was.
  Future<void> forgotPassword(String email) async {
    await _client.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  /// Sets a new password using the emailed [code]. Throws a 400 with
  /// `errors.code` or `errors.newPassword` when rejected.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  static String? _nullIfBlank(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
