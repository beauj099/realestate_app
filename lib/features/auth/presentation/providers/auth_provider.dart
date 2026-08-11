import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dto/auth_dtos.dart';
import '../../../../core/network/providers/api_providers.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

/// Sentinel used by [AuthState.copyWith] to distinguish an explicit `null`
/// argument (clear the error) from "argument not provided" (keep it).
const Object _unset = Object();

class AuthState {
  final AuthStatus status;
  final String? displayName;
  final String? role;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.displayName,
    this.role,
    this.errorMessage,
  });

  const AuthState.uninitialized()
      : status = AuthStatus.uninitialized,
        displayName = null,
        role = null,
        errorMessage = null;

  const AuthState.authenticated({
    required this.displayName,
    required this.role,
  })  : status = AuthStatus.authenticated,
        errorMessage = null;

  const AuthState.unauthenticated({this.errorMessage})
      : status = AuthStatus.unauthenticated,
        displayName = null,
        role = null;

  AuthState copyWith({Object? errorMessage = _unset}) {
    return AuthState(
      status: status,
      displayName: displayName,
      role: role,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    return const AuthState.uninitialized();
  }

  Future<void> init() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final displayName = await _storage.read(key: 'auth_display_name');
      final role = await _storage.read(key: 'auth_role');

      if (token != null && displayName != null && role != null) {
        final apiClient = ref.read(apiClientProvider);
        apiClient.setToken(token);
        apiClient.setOnUnauthorized(() => logout());
        state = AuthState.authenticated(displayName: displayName, role: role);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(errorMessage: null);

    try {
      final authService = ref.read(authApiServiceProvider);
      final response = await authService.login(
        LoginRequest(username: username, password: password),
      );

      await _storage.write(key: 'auth_token', value: response.token);
      await _storage.write(key: 'auth_display_name', value: response.displayName);
      await _storage.write(key: 'auth_role', value: response.role);

      final apiClient = ref.read(apiClientProvider);
      apiClient.setToken(response.token);
      apiClient.setOnUnauthorized(() => logout());

      state = AuthState.authenticated(
        displayName: response.displayName,
        role: response.role,
      );
    } catch (e) {
      state = AuthState.unauthenticated(
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    final apiClient = ref.read(apiClientProvider);
    apiClient.setToken(null);
    state = const AuthState.unauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
