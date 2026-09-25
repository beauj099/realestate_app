import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// On the web, `dart:io`'s [Platform] is unavailable. The web build uses the
/// backend's plain HTTP endpoint: browsers cannot be told to accept a
/// self-signed certificate (no `badCertificateCallback` exists on the web), so
/// HTTPS would always fail against the local dev cert.
String resolveDefaultBaseUrl() {
  if (ApiConstants.baseUrlOverride.isNotEmpty) {
    return ApiConstants.baseUrlOverride;
  }
  return ApiConstants.baseUrlWeb;
}

/// No-op: the browser loads images and owns the TLS handshake on the web.
void allowApiImagesWithDevCert(String baseUrl) {}

/// No-op: the browser manages the TLS handshake on the web. Web traffic is
/// routed over HTTP instead (see [resolveDefaultBaseUrl]).
void applyDebugTlsBypass(Dio dio) {}
