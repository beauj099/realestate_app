enum PropertyType {
  house,
  townhouse,
  apartment,
  vacantLand,
  plot,
}

extension PropertyTypeExtension on PropertyType {
  String get displayString {
    switch (this) {
      case PropertyType.house:
        return 'House';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.vacantLand:
        return 'Vacant Land';
      case PropertyType.plot:
        return 'Plot';
    }
  }

  static PropertyType fromString(String val) {
    switch (val.trim().toLowerCase()) {
      case 'townhouse':
        return PropertyType.townhouse;
      case 'apartment':
        return PropertyType.apartment;
      case 'vacant land':
      case 'vacantland':
        return PropertyType.vacantLand;
      case 'plot':
        return PropertyType.plot;
      case 'house':
      default:
        return PropertyType.house;
    }
  }
}
