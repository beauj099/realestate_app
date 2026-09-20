import 'package:flutter/material.dart';

enum RoomCategory {
  bedroom,
  bathroom,
  livingSpaces,
  kitchenAndUtility,
  workAndStudy,
  entertainment,
  additional,
}

extension RoomCategoryExtension on RoomCategory {
  String get displayString {
    switch (this) {
      case RoomCategory.bedroom:
        return 'Bedrooms';
      case RoomCategory.bathroom:
        return 'Bathrooms';
      case RoomCategory.livingSpaces:
        return 'Living Spaces';
      case RoomCategory.kitchenAndUtility:
        return 'Kitchen & Utility';
      case RoomCategory.workAndStudy:
        return 'Work & Study';
      case RoomCategory.entertainment:
        return 'Entertainment';
      case RoomCategory.additional:
        return 'Additional';
    }
  }

  /// Glyph shown beside every room type in this category.
  IconData get icon {
    switch (this) {
      case RoomCategory.bedroom:
        return Icons.king_bed_outlined;
      case RoomCategory.bathroom:
        return Icons.bathtub_outlined;
      case RoomCategory.livingSpaces:
        return Icons.weekend_outlined;
      case RoomCategory.kitchenAndUtility:
        return Icons.kitchen_outlined;
      case RoomCategory.workAndStudy:
        return Icons.desk_outlined;
      case RoomCategory.entertainment:
        return Icons.sports_esports_outlined;
      case RoomCategory.additional:
        return Icons.category_outlined;
    }
  }

  List<String> get predefinedRoomTypes {
    switch (this) {
      case RoomCategory.bedroom:
        return ['Bedroom', 'Main Bedroom / Master Suite'];
      case RoomCategory.bathroom:
        return [
          'En-suite Bathroom',
          'Full Bathroom',
          'Guest Toilet / Powder Room',
        ];
      case RoomCategory.livingSpaces:
        return [
          'Lounge',
          'Dining Room',
          'Open-Plan Lounge & Dining',
          'Family Room / TV Room',
          'Sunroom / Garden Room',
          'Entrance Hall / Foyer',
        ];
      case RoomCategory.kitchenAndUtility:
        return ['Kitchen', 'Scullery', 'Laundry Room', 'Pantry'];
      case RoomCategory.workAndStudy:
        return ['Study / Home Office'];
      case RoomCategory.entertainment:
        return [
          'Entertainment Room',
          'Braai Room / Indoor Braai Room',
          'Bar / Built-in Bar',
          'Wine Cellar',
          'Games Room',
        ];
      case RoomCategory.additional:
        return [
          'Loft',
          'Storeroom / Workshop',
          'Staff Quarters / Domestic Room',
          'Flatlet / Garden Cottage',
        ];
    }
  }

  static RoomCategory fromString(String val) {
    switch (val.trim().toLowerCase()) {
      case 'bedrooms':
      case 'bedroom':
        return RoomCategory.bedroom;
      case 'bathrooms':
      case 'bathroom':
        return RoomCategory.bathroom;
      case 'living spaces':
      case 'livingspaces':
        return RoomCategory.livingSpaces;
      case 'kitchen & utility':
      case 'kitchenandutility':
        return RoomCategory.kitchenAndUtility;
      case 'work & study':
      case 'workandstudy':
        return RoomCategory.workAndStudy;
      case 'entertainment':
        return RoomCategory.entertainment;
      case 'additional':
      default:
        return RoomCategory.additional;
    }
  }

  /// All predefined room types across every category.
  static List<String> get allPredefinedTypes =>
      RoomCategory.values.expand((c) => c.predefinedRoomTypes).toList();

  /// Map of predefined room type name → category's roomTypeId (index+1).
  static Map<String, int> get typeToRoomTypeId => {
    for (var c in RoomCategory.values)
      for (var t in c.predefinedRoomTypes) t: c.index + 1,
  };

  /// Resolves a predefined room type name to its roomTypeId, falling back to
  /// [additional] for unknown / custom names.
  static int roomTypeIdForType(String type) =>
      typeToRoomTypeId[type] ?? RoomCategory.additional.index + 1;

  /// Resolves a stored [roomTypeId] back to a category for display helpers.
  static RoomCategory categoryForRoomTypeId(int id) {
    if (id < 1 || id > RoomCategory.values.length) {
      return RoomCategory.additional;
    }
    return RoomCategory.values[id - 1];
  }
}
