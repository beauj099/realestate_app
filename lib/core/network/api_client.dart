import 'dart:async';

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

          try {
            _refreshCompleter ??= _onRefreshToken!().then((success) {
              if (!success) throw Exception('Refresh failed');
            });

            await _refreshCompleter;

            final opts = error.requestOptions;
            opts.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix}$_token';
            final response = await _dio.fetch(opts);
            handler.resolve(response);
          } catch (_) {
            _onUnauthorized?.call();
            handler.next(error);
          } finally {
            _refreshCompleter = null;
          }
        },
      ),
    ]);
  }

  void setToken(String? token) => _token = token;
  void setOnUnauthorized(void Function()? callback) =>
      _onUnauthorized = callback;

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
