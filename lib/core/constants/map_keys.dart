import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Keys for map imagery services, from `--dart-define=MAPTILER_KEY=…` or
/// `MAPTILER_KEY` in `.env`. Empty when not set: the feature that needs the
/// key is then not offered.
abstract final class MapKeys {
  static String get mapTiler {
    const defined = String.fromEnvironment('MAPTILER_KEY');
    if (defined.isNotEmpty) return defined;
    if (dotenv.isInitialized) return dotenv.maybeGet('MAPTILER_KEY') ?? '';
    return '';
  }
}
