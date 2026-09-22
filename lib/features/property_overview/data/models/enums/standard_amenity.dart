import 'room_category.dart';

enum AmenityCategory { kitchen, bedroomBathroom, livingAreas, generalInterior }

extension AmenityCategoryExtension on AmenityCategory {
  String get displayString {
    switch (this) {
      case AmenityCategory.kitchen:
        return 'Kitchen';
      case AmenityCategory.bedroomBathroom:
        return 'Bedroom / Bathroom';
      case AmenityCategory.livingAreas:
        return 'Living Areas';
      case AmenityCategory.generalInterior:
        return 'General Interior';
    }
  }
}

enum StandardAmenity {
  builtInCupboards('Built-in Cupboards', AmenityCategory.kitchen),
  graniteCountertops('Granite / Stone Countertops', AmenityCategory.kitchen),
  gasHob('Gas Hob', AmenityCategory.kitchen),
  eyeLevelOven('Eye-level Oven', AmenityCategory.kitchen),
  undercounterOvenHob('Undercounter Oven & Hob', AmenityCategory.kitchen),
  extractorFan('Extractor Fan', AmenityCategory.kitchen),
  kitchenIsland('Kitchen Island / Prep Bowl', AmenityCategory.kitchen),
  dishwasherConnection('Dishwasher Connection', AmenityCategory.kitchen),
  washingMachineConnection(
    'Washing Machine Connection',
    AmenityCategory.kitchen,
  ),
  breakfastNook('Breakfast Nook', AmenityCategory.kitchen),
  walkInCloset('Walk-in Closet', AmenityCategory.bedroomBathroom),
  ensuiteBathroom('En-suite Bathroom', AmenityCategory.bedroomBathroom),
  ceilingFan('Ceiling Fan', AmenityCategory.bedroomBathroom),
  balconyAccess('Balcony Access', AmenityCategory.bedroomBathroom),
  fireplace('Fireplace', AmenityCategory.livingAreas),
  underfloorHeating('Underfloor Heating', AmenityCategory.livingAreas),
  builtInBraai('Built-in Braai', AmenityCategory.livingAreas),
  builtInBar('Built-in Bar', AmenityCategory.livingAreas),
  airConditioning('Air Conditioning', AmenityCategory.livingAreas),
  tiledFloors('Tiled Floors', AmenityCategory.livingAreas),
  woodenLaminateFloors('Wooden / Laminate Floors', AmenityCategory.livingAreas),
  highCeilings(
    'High Ceilings / Exposed Beams / Exposed Trusses',
    AmenityCategory.livingAreas,
  ),
  fibreReady('Fibre Ready / Fibre Installed', AmenityCategory.generalInterior),
  alarmSystem('Alarm System', AmenityCategory.generalInterior),
  intercom('Intercom', AmenityCategory.generalInterior),
  cctv('CCTV / Security Cameras', AmenityCategory.generalInterior),
  safetyGates('Safety Gates', AmenityCategory.generalInterior);

  final String displayString;
  final AmenityCategory category;

  const StandardAmenity(this.displayString, this.category);

  static StandardAmenity? fromString(String val) {
    for (final amenity in StandardAmenity.values) {
      if (amenity.displayString.toLowerCase() == val.trim().toLowerCase()) {
        return amenity;
      }
    }
    return null;
  }

  /// Amenities relevant to one room category.
  ///
  /// Previously every room rendered every [AmenityCategory], so a Bedroom
  /// showed the full Kitchen block. Each room now only sees its own
  /// amenities plus cross-cutting finishes (floors, climate, security).
  static List<StandardAmenity> relevantForCategory(RoomCategory category) {
    switch (category) {
      case RoomCategory.bedroom:
        return const [
          StandardAmenity.walkInCloset,
          StandardAmenity.ensuiteBathroom,
          StandardAmenity.ceilingFan,
          StandardAmenity.balconyAccess,
          StandardAmenity.tiledFloors,
          StandardAmenity.woodenLaminateFloors,
          StandardAmenity.airConditioning,
          StandardAmenity.underfloorHeating,
          StandardAmenity.highCeilings,
          StandardAmenity.fibreReady,
          StandardAmenity.alarmSystem,
          StandardAmenity.intercom,
          StandardAmenity.cctv,
          StandardAmenity.safetyGates,
        ];
      case RoomCategory.bathroom:
        return const [
          StandardAmenity.tiledFloors,
          StandardAmenity.underfloorHeating,
          StandardAmenity.airConditioning,
          StandardAmenity.highCeilings,
          StandardAmenity.fibreReady,
          StandardAmenity.alarmSystem,
          StandardAmenity.intercom,
          StandardAmenity.cctv,
          StandardAmenity.safetyGates,
        ];
      case RoomCategory.livingSpaces:
      case RoomCategory.entertainment:
        return StandardAmenity.values
            .where(
              (a) =>
                  a.category == AmenityCategory.livingAreas ||
                  a.category == AmenityCategory.generalInterior,
            )
            .toList();
      case RoomCategory.kitchenAndUtility:
        return const [
          StandardAmenity.builtInCupboards,
          StandardAmenity.graniteCountertops,
          StandardAmenity.gasHob,
          StandardAmenity.eyeLevelOven,
          StandardAmenity.undercounterOvenHob,
          StandardAmenity.extractorFan,
          StandardAmenity.kitchenIsland,
          StandardAmenity.dishwasherConnection,
          StandardAmenity.washingMachineConnection,
          StandardAmenity.breakfastNook,
          StandardAmenity.tiledFloors,
          StandardAmenity.woodenLaminateFloors,
          StandardAmenity.airConditioning,
          StandardAmenity.underfloorHeating,
          StandardAmenity.fibreReady,
          StandardAmenity.alarmSystem,
          StandardAmenity.intercom,
          StandardAmenity.cctv,
          StandardAmenity.safetyGates,
        ];
      case RoomCategory.workAndStudy:
        return const [
          StandardAmenity.fibreReady,
          StandardAmenity.alarmSystem,
          StandardAmenity.intercom,
          StandardAmenity.cctv,
          StandardAmenity.safetyGates,
          StandardAmenity.airConditioning,
          StandardAmenity.tiledFloors,
          StandardAmenity.woodenLaminateFloors,
          StandardAmenity.underfloorHeating,
          StandardAmenity.highCeilings,
          StandardAmenity.balconyAccess,
          StandardAmenity.ceilingFan,
        ];
      case RoomCategory.additional:
        return StandardAmenity.values;
    }
  }

  /// Convenience lookup from the stored `roomTypeId` (index+1).
  static List<StandardAmenity> relevantForRoomTypeId(int roomTypeId) =>
      relevantForCategory(
        RoomCategoryExtension.categoryForRoomTypeId(roomTypeId),
      );
}
