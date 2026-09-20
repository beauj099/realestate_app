class NominatimResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? houseNumber;
  final String? road;
  final String? suburb;
  final String? neighbourhood;
  final String? city;
  final String? town;
  final String? village;
  final String? state;
  final String? postcode;
  final String? country;
  final String? countryCode;

  const NominatimResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.houseNumber,
    this.road,
    this.suburb,
    this.neighbourhood,
    this.city,
    this.town,
    this.village,
    this.state,
    this.postcode,
    this.country,
    this.countryCode,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final displayName = json['display_name'] as String? ?? '';

    // Nominatim returns house_number as a string for most records but as a
    // number for some imports, so normalise rather than cast.
    String? asText(Object? value) {
      final text = value?.toString().trim();
      return (text == null || text.isEmpty) ? null : text;
    }

    return NominatimResult(
      displayName: displayName,
      latitude: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
      houseNumber:
          asText(address['house_number']) ?? _houseNumberFrom(displayName),
      road: asText(address['road']),
      suburb: asText(address['suburb']),
      neighbourhood: asText(address['neighbourhood']),
      city: asText(address['city']),
      town: asText(address['town']),
      village: asText(address['village']),
      state: asText(address['state']),
      postcode: asText(address['postcode']),
      country: asText(address['country']),
      countryCode: asText(address['country_code']),
    );
  }

  /// Pulls a street number out of the leading segment of `display_name`.
  ///
  /// Reverse geocoding a GPS fix often resolves to the road rather than the
  /// building, so `address.house_number` comes back absent even though the
  /// formatted display name starts with the number ("12 Long Street, …").
  /// Recovering it here is what makes "Detect my address" fill the Street
  /// Number field instead of leaving it blank.
  static String? _houseNumberFrom(String displayName) {
    if (displayName.isEmpty) return null;
    final first = displayName.split(',').first.trim();
    if (first.isEmpty) return null;

    // A bare number, or a number with a unit suffix such as "12A" or "12-14".
    if (_looksLikeHouseNumber(first)) return first;

    // "12 Long Street" — take the leading numeric token.
    final leading = RegExp(r'^(\d+[A-Za-z]?(?:\s*[-/]\s*\d+[A-Za-z]?)?)\s+')
        .firstMatch(first);
    return leading?.group(1)?.trim();
  }

  static bool _looksLikeHouseNumber(String value) =>
      RegExp(r'^\d+[A-Za-z]?(?:\s*[-/]\s*\d+[A-Za-z]?)?$').hasMatch(value);

  String get cityOrTown => city ?? town ?? village ?? '';
}
