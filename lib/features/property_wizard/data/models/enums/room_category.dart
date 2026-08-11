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

  List<String> get predefinedRoomTypes {
    switch (this) {
      case RoomCategory.bedroom:
        return [
          'Bedroom',
          'Main Bedroom / Master Suite',
        ];
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
        return [
          'Kitchen',
          'Scullery',
          'Laundry Room',
          'Pantry',
        ];
      case RoomCategory.workAndStudy:
        return [
          'Study / Home Office',
        ];
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
}
