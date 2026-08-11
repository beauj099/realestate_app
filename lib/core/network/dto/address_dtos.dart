class UpsertAddressRequest {
  final String? erfNumber;
  final String? estateName;
  final String? streetNumber;
  final String? unitNumber;
  final String? street;
  final String? suburb;
  final String? city;
  final String? province;
  final String? country;
  final String? postalCode;
  final num? latitude;
  final num? longitude;

  const UpsertAddressRequest({
    this.erfNumber,
    this.estateName,
    this.streetNumber,
    this.unitNumber,
    this.street,
    this.suburb,
    this.city,
    this.province,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        if (erfNumber != null && erfNumber!.isNotEmpty) 'erfNumber': erfNumber,
        if (estateName != null && estateName!.isNotEmpty)
          'estateName': estateName,
        if (streetNumber != null && streetNumber!.isNotEmpty)
          'streetNumber': streetNumber,
        if (unitNumber != null && unitNumber!.isNotEmpty)
          'unitNumber': unitNumber,
        if (street != null && street!.isNotEmpty) 'street': street,
        if (suburb != null && suburb!.isNotEmpty) 'suburb': suburb,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (province != null && province!.isNotEmpty) 'province': province,
        if (country != null && country!.isNotEmpty) 'country': country,
        if (postalCode != null && postalCode!.isNotEmpty)
          'postalCode': postalCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}

class ListingAddressDto {
  final int listingAddressId;
  final int listingId;
  final String? erfNumber;
  final String? estateName;
  final String? streetNumber;
  final String? unitNumber;
  final String? street;
  final String? suburb;
  final String? city;
  final String? province;
  final String? country;
  final String? postalCode;
  final num? latitude;
  final num? longitude;

  const ListingAddressDto({
    required this.listingAddressId,
    required this.listingId,
    this.erfNumber,
    this.estateName,
    this.streetNumber,
    this.unitNumber,
    this.street,
    this.suburb,
    this.city,
    this.province,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory ListingAddressDto.fromJson(Map<String, dynamic> json) {
    return ListingAddressDto(
      listingAddressId: json['listingAddressId'] as int,
      listingId: json['listingId'] as int,
      erfNumber: json['erfNumber'] as String?,
      estateName: json['estateName'] as String?,
      streetNumber: json['streetNumber'] as String?,
      unitNumber: json['unitNumber'] as String?,
      street: json['street'] as String?,
      suburb: json['suburb'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
    );
  }
}
