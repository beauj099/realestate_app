/// An address offered while the agent types (`GET /api/property/suggest`),
/// from the City of Cape Town's parcel records. With a street number it is a
/// real erf, with its location; a bare street has neither, and the agent adds
/// the number.
class AddressSuggestion {
  final String label;
  final String? streetNumber;
  final String streetName;
  final String suburb;
  final String city;
  final String province;
  final String country;
  final String? erf;
  final double? lat;
  final double? lng;

  const AddressSuggestion({
    required this.label,
    required this.streetName,
    required this.suburb,
    required this.city,
    required this.province,
    required this.country,
    this.streetNumber,
    this.erf,
    this.lat,
    this.lng,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> j) =>
      AddressSuggestion(
        label: j['label'] as String? ?? '',
        streetNumber: j['streetNumber'] as String?,
        streetName: j['streetName'] as String? ?? '',
        suburb: j['suburb'] as String? ?? '',
        city: j['city'] as String? ?? '',
        province: j['province'] as String? ?? '',
        country: j['country'] as String? ?? '',
        erf: j['erf'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  /// A numbered address, i.e. one erf — not just a street.
  bool get isProperty => streetNumber != null && erf != null;
}
