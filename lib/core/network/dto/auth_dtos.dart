class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});
}

class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final String displayName;
  final String role;
  final String refreshToken;

  const LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.displayName,
    required this.role,
    required this.refreshToken,
  });
}

class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});
}

class RefreshTokenResponse {
  final String token;
  final DateTime expiresAt;
  final String refreshToken;

  const RefreshTokenResponse({
    required this.token,
    required this.expiresAt,
    required this.refreshToken,
  });
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String mobile;
  final String agencyName;
  final String agencyRegistrationNumber;
  final String licenceNumber;
  final String password;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.agencyName,
    required this.agencyRegistrationNumber,
    required this.licenceNumber,
    required this.password,
  });
}
