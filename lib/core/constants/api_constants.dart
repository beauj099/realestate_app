import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Network configuration constants.
abstract final class ApiConstants {
  static const String baseUrlAndroid = 'https://10.0.2.2:7063';
  static const String baseUrlDesktop = 'https://localhost:7063';

  /// Browsers own TLS validation and cannot be made to accept the self-signed
  /// dev cert, so the web build talks to the backend over plain HTTP instead.
  static const String baseUrlWeb = 'http://localhost:5169';

  /// The live API. Release builds use it unless told otherwise, so a plain
  /// `flutter build apk --release` talks to the real server.
  static const String baseUrlProduction = 'https://api.realworth.co.za';

  /// The backend base URL, in order:
  /// 1. `--dart-define=API_BASE_URL=https://...` at build time, for a release
  ///    against another server (e.g. a test API);
  /// 2. in a release build, [baseUrlProduction] (never a developer's `.env`,
  ///    whose emulator address leads nowhere on a real phone);
  /// 3. in debug and profile builds, `API_BASE_URL` from the `.env` file.
  /// Empty when none applies, in which case [baseUrlAndroid]/[baseUrlDesktop]
  /// are used.
  static String get baseUrlOverride {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    if (kReleaseMode) return baseUrlProduction;
    if (dotenv.isInitialized) {
      final envUrl = dotenv.maybeGet('API_BASE_URL');
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    }
    return '';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';

  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
