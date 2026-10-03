import 'package:flutter/material.dart';

/// Property types offered in the wizard.
///
/// Ordinal position maps to the backend `PropertyType` id (index + 1), so the
/// order of these entries is load-bearing — do not reorder or insert.
///
/// `commercial` occupies the slot the backend still seeds as "Vacant Land".
/// Vacant land and plot described the same thing, so the slot was repurposed
/// rather than adding a sixth id the database has no row for. Renaming the
/// backing row is tracked in `docs/BACKEND_CHANGES.md`.
enum PropertyType {
  house,
  townhouse,
  apartment,
  commercial,
  plot,

  /// Id 6 (patch 2026-10-03_listing_details_json.sql). Appended: the
  /// position is the backend id.
  vacantLand,
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
      case PropertyType.commercial:
        return 'Commercial Property';
      case PropertyType.plot:
        return 'Plot';
      case PropertyType.vacantLand:
        return 'Vacant Land';
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyType.house:
        return Icons.home_outlined;
      case PropertyType.townhouse:
        return Icons.business_outlined;
      case PropertyType.apartment:
        return Icons.corporate_fare_outlined;
      case PropertyType.commercial:
        return Icons.storefront_outlined;
      case PropertyType.plot:
        return Icons.grid_view_outlined;
      case PropertyType.vacantLand:
        return Icons.landscape_outlined;
    }
  }

  /// Backend `PropertyType` id for this entry.
  int get id => index + 1;

  static PropertyType fromString(String val) {
    switch (val.trim().toLowerCase()) {
      case 'townhouse':
        return PropertyType.townhouse;
      case 'apartment':
        return PropertyType.apartment;
      case 'commercial':
      case 'commercial property':
        return PropertyType.commercial;
      // Slot 4 was once seeded as "Vacant Land"; the database now calls it
      // Commercial Property, and vacant land has its own row (6).
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

  /// Resolves a stored backend id, or `null` when nothing is selected yet.
  static PropertyType? fromId(int id) {
    if (id < 1 || id > PropertyType.values.length) return null;
    return PropertyType.values[id - 1];
  }
}
