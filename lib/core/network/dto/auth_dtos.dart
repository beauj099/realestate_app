class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final String displayName;
  final String role;

  const LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.displayName,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }
}
