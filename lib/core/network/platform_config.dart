import 'package:dio/dio.dart';

import 'platform_config_io.dart'
    if (dart.library.html) 'platform_config_web.dart'
    as platform;

/// Resolves the default backend base URL for the current platform.
String resolveDefaultBaseUrl() => platform.resolveDefaultBaseUrl();

/// Applies the debug-mode TLS certificate bypass. On the web this is a no-op:
/// the browser owns the TLS handshake.
void applyDebugTlsBypass(Dio dio) => platform.applyDebugTlsBypass(dio);

/// Lets `Image.network` load photos from the API host despite its dev
/// certificate. No-op on the web.
void allowApiImagesWithDevCert(String baseUrl) =>
    platform.allowApiImagesWithDevCert(baseUrl);
