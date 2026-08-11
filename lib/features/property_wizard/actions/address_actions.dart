import '../data/models/property_state.dart';

extension AddressActions on PropertyState {
  PropertyState withAddress({
    String? streetNumber,
    String? street,
    String? unitNumber,
    String? suburb,
    String? city,
    String? province,
    String? country,
    String? postalCode,
  }) {
    return copyWith(
      streetNumber: streetNumber ?? this.streetNumber,
      street: street ?? this.street,
      unitNumber: unitNumber ?? this.unitNumber,
      suburb: suburb ?? this.suburb,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  PropertyState withIdentifiers({
    String? estateName,
    String? erfNumber,
  }) {
    return copyWith(
      estateName: estateName ?? this.estateName,
      erfNumber: erfNumber ?? this.erfNumber,
    );
  }

  PropertyState withCoordinates({
    double? latitude,
    double? longitude,
  }) {
    return copyWith(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
