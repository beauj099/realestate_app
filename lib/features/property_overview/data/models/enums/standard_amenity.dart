import 'room_category.dart';

/// Heading a room amenity is listed under on the room screen.
enum AmenityCategory {
  kitchen,
  bathroom,
  storage,
  layout,
  living,
  floors,
  climateFinishes,

  /// TV, data and telephone points (myEdge: TV Port, Internet Port).
  connections,

  /// Whole-house items once offered per room (alarm, CCTV, fibre, …). They
  /// belong on the property — see the outdoor Security section — so they are
  /// never offered for a room, only shown on older rooms that already have one.
  legacyWholeHouse,
}

extension AmenityCategoryExtension on AmenityCategory {
  String get displayString {
    switch (this) {
      case AmenityCategory.kitchen:
        return 'Kitchen & Utility';
      case AmenityCategory.bathroom:
        return 'Bathroom';
      case AmenityCategory.storage:
        return 'Storage';
      case AmenityCategory.layout:
        return 'Layout & Access';
      case AmenityCategory.living:
        return 'Living & Entertainment';
      case AmenityCategory.floors:
        return 'Floors';
      case AmenityCategory.climateFinishes:
        return 'Climate & Finishes';
      case AmenityCategory.connections:
        return 'Connections';
      case AmenityCategory.legacyWholeHouse:
        return 'Whole House';
    }
  }
}

/// A predefined room feature.
///
/// [displayString] is also how the API matches a feature to its lookup row,
/// so existing strings must not be reworded. New entries without a lookup row
/// are saved as custom features.
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
  // From the myEdge listing form (2026-10).
  stove('Stove', AmenityCategory.kitchen),
  fridgeSpace('Fridge Space', AmenityCategory.kitchen),
  tumbleDryerConnection('Tumble Dryer Connection', AmenityCategory.kitchen),
  wasteDisposal('Waste Disposal', AmenityCategory.kitchen),
  bath('Bath', AmenityCategory.bathroom),
  shower('Shower', AmenityCategory.bathroom),
  doubleVanity('Double Vanity', AmenityCategory.bathroom),
  heatedTowelRail('Heated Towel Rail', AmenityCategory.bathroom),
  separateToilet('Separate Toilet', AmenityCategory.bathroom),
  jacuzziBath('Jacuzzi Bath', AmenityCategory.bathroom),
  basin('Basin', AmenityCategory.bathroom),
  toilet('Toilet', AmenityCategory.bathroom),
  walkInCloset('Walk-in Closet', AmenityCategory.storage),
  builtInWardrobes('Built-in Wardrobes', AmenityCategory.storage),
  ensuiteBathroom('En-suite Bathroom', AmenityCategory.layout),
  balconyAccess('Balcony Access', AmenityCategory.layout),
  openPlan('Open Plan', AmenityCategory.layout),
  slidingDoors('Sliding Doors', AmenityCategory.layout),
  staircase('Staircase', AmenityCategory.layout),
  patioAccess('Patio Access', AmenityCategory.layout),
  fireplace('Fireplace', AmenityCategory.living),
  builtInBraai('Built-in Braai', AmenityCategory.living),
  builtInBar('Built-in Bar', AmenityCategory.living),
  projector('Projector', AmenityCategory.living),
  tiledFloors('Tiled Floors', AmenityCategory.floors),
  woodenLaminateFloors('Wooden / Laminate Floors', AmenityCategory.floors),
  carpets('Carpets', AmenityCategory.floors),
  parquetFloors('Parquet Floors', AmenityCategory.floors),
  airConditioning('Air Conditioning', AmenityCategory.climateFinishes),
  ceilingFan('Ceiling Fan', AmenityCategory.climateFinishes),
  underfloorHeating('Underfloor Heating', AmenityCategory.climateFinishes),
  highCeilings(
    'High Ceilings / Exposed Beams / Exposed Trusses',
    AmenityCategory.climateFinishes,
  ),
  blinds('Blinds', AmenityCategory.climateFinishes),
  curtainRails('Curtain Rails', AmenityCategory.climateFinishes),
  pressedCeilings('Pressed Ceilings', AmenityCategory.climateFinishes),
  woodenCeilings('Wooden Ceilings', AmenityCategory.climateFinishes),
  skylight('Skylight', AmenityCategory.climateFinishes),
  tvPort('TV Port', AmenityCategory.connections),
  dataPort('Data / Internet Port', AmenityCategory.connections),
  telephonePort('Telephone Port', AmenityCategory.connections),
  fibreReady('Fibre Ready / Fibre Installed', AmenityCategory.legacyWholeHouse),
  alarmSystem('Alarm System', AmenityCategory.legacyWholeHouse),
  intercom('Intercom', AmenityCategory.legacyWholeHouse),
  cctv('CCTV / Security Cameras', AmenityCategory.legacyWholeHouse),
  safetyGates('Safety Gates', AmenityCategory.legacyWholeHouse);

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

  static List<StandardAmenity> _inCategories(Set<AmenityCategory> categories) =>
      StandardAmenity.values
          .where((a) => categories.contains(a.category))
          .toList();

  /// Amenities offered for one room category — only what can actually be
  /// found in that kind of room. Whole-house items are never offered.
  static List<StandardAmenity> relevantForCategory(RoomCategory category) {
    switch (category) {
      case RoomCategory.bedroom:
        return _inCategories({
          AmenityCategory.storage,
          AmenityCategory.layout,
          AmenityCategory.floors,
          AmenityCategory.climateFinishes,
          AmenityCategory.connections,
        });
      case RoomCategory.bathroom:
        return [
          ..._inCategories({AmenityCategory.bathroom}),
          StandardAmenity.tiledFloors,
          StandardAmenity.underfloorHeating,
        ];
      case RoomCategory.livingSpaces:
      case RoomCategory.entertainment:
        return [
          ..._inCategories({
            AmenityCategory.living,
            AmenityCategory.floors,
            AmenityCategory.climateFinishes,
            AmenityCategory.connections,
          }),
          StandardAmenity.balconyAccess,
          StandardAmenity.openPlan,
          StandardAmenity.slidingDoors,
          StandardAmenity.patioAccess,
        ];
      case RoomCategory.kitchenAndUtility:
        return [
          ..._inCategories({AmenityCategory.kitchen}),
          StandardAmenity.openPlan,
          StandardAmenity.tiledFloors,
          StandardAmenity.woodenLaminateFloors,
          StandardAmenity.underfloorHeating,
        ];
      case RoomCategory.workAndStudy:
        return [
          StandardAmenity.balconyAccess,
          ..._inCategories({
            AmenityCategory.floors,
            AmenityCategory.climateFinishes,
            AmenityCategory.connections,
          }),
        ];
      case RoomCategory.additional:
        // Lofts, storerooms, flatlets: too varied to narrow down.
        return StandardAmenity.values
            .where((a) => a.category != AmenityCategory.legacyWholeHouse)
            .toList();
    }
  }

  /// Convenience lookup from the stored `roomTypeId` (index+1).
  static List<StandardAmenity> relevantForRoomTypeId(int roomTypeId) =>
      relevantForCategory(
        RoomCategoryExtension.categoryForRoomTypeId(roomTypeId),
      );
}
