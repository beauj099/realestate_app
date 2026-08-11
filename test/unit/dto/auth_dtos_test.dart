import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/network/dto/auth_dtos.dart';

void main() {
  group('LoginRequest', () {
    test('toJson() returns correct map', () {
      final request = LoginRequest(username: 'agent', password: 'secret');

      final json = request.toJson();

      expect(json['username'], 'agent');
      expect(json['password'], 'secret');
    });
  });

  group('LoginResponse', () {
    test('fromJson() parses response correctly', () {
      final json = {
        'token': 'abc123',
        'expiresAt': '2026-12-31T23:59:59.000',
        'displayName': 'John Agent',
        'role': 'agent',
      };

      final response = LoginResponse.fromJson(json);

      expect(response.token, 'abc123');
      expect(response.expiresAt.year, 2026);
      expect(response.displayName, 'John Agent');
      expect(response.role, 'agent');
    });
  });
}
