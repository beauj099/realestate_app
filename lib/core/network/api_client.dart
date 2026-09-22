import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../constants/api_constants.dart';
import 'api_endpoints.dart';
import 'platform_config.dart';

class ApiClient {
  final Dio _dio;
  String? _token;
  void Function()? _onUnauthorized;
  Future<bool> Function()? _onRefreshToken;
  Future<void>? _refreshCompleter;

  ApiClient({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? resolveDefaultBaseUrl(),
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': ApiConstants.contentTypeJson,
            'Accept': ApiConstants.acceptJson,
          },
          followRedirects: true,
        ),
      ) {
    // Only bypass TLS certificate validation in debug builds on native
    // platforms, where the local dev backend serves a self-signed cert. The
    // web is unaffected: the browser owns TLS validation there.
    applyDebugTlsBypass(_dio);
    _dio.interceptors.addAll([
      LogInterceptor(requestBody: kDebugMode, responseBody: kDebugMode),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix}$_token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          final path = error.requestOptions.path;
          final isLoginOrRegister =
              path.contains(ApiEndpoints.login) ||
              path.contains(ApiEndpoints.register);

          if (isLoginOrRegister) {
            // A failed login/register must not wipe an existing session.
            handler.next(error);
            return;
          }

          if (path.contains(ApiEndpoints.refresh)) {
            _onUnauthorized?.call();
            handler.next(error);
            return;
          }

          if (_onRefreshToken == null) {
            _onUnauthorized?.call();
            handler.next(error);
            return;
          }

          // The retry itself goes through these interceptors, so a server
          // that keeps answering 401 must not loop refresh -> retry forever.
          if (error.requestOptions.extra['authRetried'] == true) {
            _onUnauthorized?.call();
            handler.next(error);
            return;
          }

          Object? refreshError;
          try {
            _refreshCompleter ??= _onRefreshToken!().then((success) {
              if (!success) throw Exception('Refresh failed');
            });

            await _refreshCompleter;
          } catch (e) {
            refreshError = e;
          } finally {
            _refreshCompleter = null;
          }

          if (refreshError != null) {
            // The session itself is dead (missing/expired refresh token):
            // sign out so the router returns to login with a clear cause.
            developer.log(
              'Token refresh failed ($refreshError); signing out.',
              name: 'ApiClient',
            );
            _onUnauthorized?.call();
            handler.next(error);
            return;
          }

          try {
            final opts = error.requestOptions;
            opts.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix}$_token';
            opts.extra['authRetried'] = true;
            if (opts.data is FormData) {
              // FormData is single-use: the first attempt finalizes it, so a
              // 401 -> refresh -> retry would crash with "The FormData has
              // already been finalized". Clone it for the retry.
              opts.data = (opts.data as FormData).clone();
              // Let Dio recompute the body length for the cloned payload.
              opts.headers.remove('Content-Length');
              opts.headers.remove('content-length');
            }
            final response = await _dio.fetch(opts);
            developer.log('Retry after refresh succeeded.', name: 'ApiClient');
            handler.resolve(response);
          } on DioException catch (retryError) {
            if (retryError.response?.statusCode == 401) {
              // The fresh token was rejected too: the session is unusable.
              developer.log(
                'Retry after refresh still 401; signing out.',
                name: 'ApiClient',
              );
              _onUnauthorized?.call();
            } else {
              // Non-auth retry failure (network, timeout, ...): the session
              // may still be fine, so keep it and surface the real error.
              developer.log(
                'Retry after refresh failed (${retryError.type}); '
                'keeping session.',
                name: 'ApiClient',
              );
            }
            handler.next(retryError);
          }
        },
      ),
    ]);
  }
  void setToken(String? token) => _token = token;
  void setOnUnauthorized(void Function()? callback) =>
      _onUnauthorized = callback;

  /// The backend root this client talks to. Needed to resolve app-relative
  /// photo paths (`/uploads/...` from the temporary local storage) into
  /// loadable URLs.
  String get baseUrl => _dio.options.baseUrl;

  void setOnRefreshToken(Future<bool> Function()? callback) =>
      _onRefreshToken = callback;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
