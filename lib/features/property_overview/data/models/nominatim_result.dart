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
    return NominatimResult(
      displayName: json['display_name'] as String? ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
      houseNumber: address['house_number'] as String?,
      road: address['road'] as String?,
      suburb: address['suburb'] as String?,
      neighbourhood: address['neighbourhood'] as String?,
      city: address['city'] as String?,
      town: address['town'] as String?,
      village: address['village'] as String?,
      state: address['state'] as String?,
      postcode: address['postcode'] as String?,
      country: address['country'] as String?,
      countryCode: address['country_code'] as String?,
    );
  }

  String get cityOrTown => city ?? town ?? village ?? '';
}
