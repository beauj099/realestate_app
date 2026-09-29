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

/// Whether [host] is a development backend (this machine, the Android
/// emulator's alias for it, or a private network address), the only hosts
/// whose self-signed certificate may be accepted. The live API has a real
/// certificate, and a release build must never skip checking it.
bool isDevHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
    return true;
  }
  final parts = host.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null)) return false;
  final (a, b) = (parts[0]!, parts[1]!);
  return a == 10 || (a == 192 && b == 168) || (a == 172 && b >= 16 && b <= 31);
}

/// Lets images load from the API despite its self-signed dev certificate.
///
/// [applyDebugTlsBypass] only covers Dio, but `Image.network` opens its own
/// `HttpClient`, so every photo served by the API failed the TLS handshake and
/// showed "Unavailable". The override accepts a bad certificate **only** for
/// the API's own host, and only when that is a dev host ([isDevHost]); every
/// other host is still validated normally.
void allowApiImagesWithDevCert(String baseUrl) {
  final apiHost = Uri.tryParse(baseUrl)?.host;
  if (apiHost == null || apiHost.isEmpty || !isDevHost(apiHost)) return;
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

/// Accepts the self-signed dev certificate of a local backend ([isDevHost]);
/// every other host, the live API included, is validated normally.
void applyDebugTlsBypass(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => isDevHost(host);
      return client;
    },
  );
}
