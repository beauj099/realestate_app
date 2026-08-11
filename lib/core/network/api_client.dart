import 'dart:io' show Platform, HttpClient;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  /// Backend base URL, injectable at build time via
  /// `--dart-define=API_BASE_URL=https://...`. Falls back to local dev hosts.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _defaultBaseUrl() {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return Platform.isAndroid
        ? 'https://10.0.2.2:7063'
        : 'https://localhost:7063';
  }

  final Dio _dio;
  String? _token;
  void Function()? _onUnauthorized;

  ApiClient({String? baseUrl}) : _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _defaultBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      followRedirects: true,
    )) {
    // Only bypass TLS certificate validation in debug builds (self-signed
    // local dev certs). Release builds use the platform's default validation.
    if (kDebugMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    // Request/response bodies can contain credentials and bearer tokens, so
    // only log them in debug builds.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  void setToken(String? token) => _token = token;
  void setOnUnauthorized(void Function()? callback) => _onUnauthorized = callback;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
