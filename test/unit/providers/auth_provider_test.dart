import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('AuthState.uninitialized() sets status correctly', () {
      const state = AuthState.uninitialized();

      expect(state.status, AuthStatus.uninitialized);
      expect(state.displayName, isNull);
      expect(state.role, isNull);
      expect(state.errorMessage, isNull);
    });

    test('AuthState.authenticated() sets status correctly', () {
      const state = AuthState.authenticated(
        displayName: 'John Agent',
        role: 'agent',
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.displayName, 'John Agent');
      expect(state.role, 'agent');
      expect(state.errorMessage, isNull);
    });

    test('AuthState.unauthenticated() sets status correctly', () {
      const state = AuthState.unauthenticated();

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.displayName, isNull);
      expect(state.role, isNull);
    });

    test('AuthState.unauthenticated() with error message', () {
      const state = AuthState.unauthenticated(errorMessage: 'Login failed');

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Login failed');
    });

    test('copyWith() updates error message', () {
      const state = AuthState.unauthenticated();

      final updated = state.copyWith(errorMessage: 'Network error');

      expect(updated.status, AuthStatus.unauthenticated);
      expect(updated.errorMessage, 'Network error');
    });
  });
}
