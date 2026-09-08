import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure_mapper.dart';
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

  const AuthState.authenticated({required this.displayName, required this.role})
    : status = AuthStatus.authenticated,
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
      final raw = await _storage.read(key: AppConstants.storageAuthKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final displayName = data['displayName'] as String?;
        final role = data['role'] as String?;

        if (token != null && displayName != null && role != null) {
          final apiClient = ref.read(apiClientProvider);
          apiClient.setToken(token);
          apiClient.setOnUnauthorized(() => logout());
          apiClient.setOnRefreshToken(() => refreshAuth());
          state = AuthState.authenticated(displayName: displayName, role: role);
        } else {
          state = const AuthState.unauthenticated();
        }
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
      final response = await authService.login(username, password);

      try {
        await _storage.write(
          key: AppConstants.storageAuthKey,
          value: jsonEncode({
            'token': response.token,
            'refreshToken': response.refreshToken,
            'displayName': response.displayName,
            'role': response.role,
          }),
        );
      } catch (e) {
        debugPrint('AuthProvider: failed to persist auth, continuing: $e');
      }

      final apiClient = ref.read(apiClientProvider);
      apiClient.setToken(response.token);
      apiClient.setOnUnauthorized(() => logout());
      apiClient.setOnRefreshToken(() => refreshAuth());

      state = AuthState.authenticated(
        displayName: response.displayName,
        role: response.role,
      );
    } catch (e) {
      debugPrint('AuthProvider: login failed: $e');
      state = AuthState.unauthenticated(errorMessage: mapFailure(e).message);
    }
  }

  Future<bool> refreshAuth() async {
    try {
      final raw = await _storage.read(key: AppConstants.storageAuthKey);
      if (raw == null) return false;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final currentRefreshToken = data['refreshToken'] as String?;
      if (currentRefreshToken == null) return false;

      final authService = ref.read(authApiServiceProvider);
      final response = await authService.refreshToken(currentRefreshToken);

      await _storage.write(
        key: AppConstants.storageAuthKey,
        value: jsonEncode({
          'token': response.token,
          'refreshToken': response.refreshToken,
          'displayName': data['displayName'],
          'role': data['role'],
        }),
      );

      final apiClient = ref.read(apiClientProvider);
      apiClient.setToken(response.token);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String mobile,
    required String agencyName,
    required String agencyRegistrationNumber,
    required String licenceNumber,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);

    try {
      final authService = ref.read(authApiServiceProvider);
      final response = await authService.register(
        fullName: fullName,
        email: email,
        mobile: mobile,
        agencyName: agencyName,
        agencyRegistrationNumber: agencyRegistrationNumber,
        licenceNumber: licenceNumber,
        password: password,
      );

      try {
        await _storage.write(
          key: AppConstants.storageAuthKey,
          value: jsonEncode({
            'token': response.token,
            'refreshToken': response.refreshToken,
            'displayName': response.displayName,
            'role': response.role,
          }),
        );
      } catch (e) {
        debugPrint('AuthProvider: failed to persist auth, continuing: $e');
      }

      final apiClient = ref.read(apiClientProvider);
      apiClient.setToken(response.token);
      apiClient.setOnUnauthorized(() => logout());
      apiClient.setOnRefreshToken(() => refreshAuth());

      state = AuthState.authenticated(
        displayName: response.displayName,
        role: response.role,
      );
    } catch (e) {
      debugPrint('AuthProvider: register failed: $e');
      state = AuthState.unauthenticated(errorMessage: mapFailure(e).message);
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
