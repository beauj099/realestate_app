import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Network configuration constants.
abstract final class ApiConstants {
  static const String baseUrlAndroid = 'https://10.0.2.2:7063';
  static const String baseUrlDesktop = 'https://localhost:7063';

  /// Browsers own TLS validation and cannot be made to accept the self-signed
  /// dev cert, so the web build talks to the backend over plain HTTP instead.
  static const String baseUrlWeb = 'http://localhost:5169';

  /// The live API, which release builds use: `flutter build appbundle
  /// --dart-define=API_BASE_URL=$baseUrlProduction`.
  static const String baseUrlProduction = 'https://api.realworth.co.za';

  /// Backend base URL injected at build time via
  /// `--dart-define=API_BASE_URL=https://...` (wins, so a release build is
  /// never pointed at a developer's `.env`) or else at runtime via the `.env`
  /// file. Empty when neither is supplied, in which case [baseUrlAndroid]/
  /// [baseUrlDesktop] are used.
  static String get baseUrlOverride {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
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
