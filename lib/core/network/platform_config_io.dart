import 'dart:io' show HttpClient, HttpOverrides, Platform, SecurityContext;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../constants/api_constants.dart';

/// Resolves the default backend base URL for native platforms.
String resolveDefaultBaseUrl() {
  if (ApiConstants.baseUrlOverride.isNotEmpty) {
    return ApiConstants.baseUrlOverride;
  }
  return Platform.isAndroid
      ? ApiConstants.baseUrlAndroid
      : ApiConstants.baseUrlDesktop;
}

/// Lets images load from the API despite its self-signed dev certificate.
///
/// [applyDebugTlsBypass] only covers Dio, but `Image.network` opens its own
/// `HttpClient`, so every photo served by the API failed the TLS handshake and
/// showed "Unavailable". The override accepts a bad certificate **only** for
/// the API's own host; every other host is still validated normally.
void allowApiImagesWithDevCert(String baseUrl) {
  final apiHost = Uri.tryParse(baseUrl)?.host;
  if (apiHost == null || apiHost.isEmpty) return;
  HttpOverrides.global = _ApiHostCertOverrides(apiHost);
}

class _ApiHostCertOverrides extends HttpOverrides {
  final String apiHost;

  _ApiHostCertOverrides(this.apiHost);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => host == apiHost;
  }
}

/// Bypasses the self-signed dev cert validation for the local backend.
void applyDebugTlsBypass(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    },
  );
}
