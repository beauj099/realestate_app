enum OutdoorExtraCategory {
  parking,
  outdoorLiving,
  extraStructures,
  security,
  energyWater,
  lifestyle,
}

extension OutdoorExtraCategoryExtension on OutdoorExtraCategory {
  String get displayString {
    switch (this) {
      case OutdoorExtraCategory.parking:
        return 'Parking';
      case OutdoorExtraCategory.outdoorLiving:
        return 'Outdoor Living';
      case OutdoorExtraCategory.extraStructures:
        return 'Extra Structures';
      case OutdoorExtraCategory.security:
        return 'Security';
      case OutdoorExtraCategory.energyWater:
        return 'Energy & Water';
      case OutdoorExtraCategory.lifestyle:
        return 'Lifestyle';
    }
  }

  List<String> get displayStrings => OutdoorExtra.values
      .where((e) => e.category == this)
      .map((e) => e.displayString)
      .toList();
}

enum OutdoorExtra {
  singleGarage('Single Garage', OutdoorExtraCategory.parking),
  doubleGarage('Double Garage', OutdoorExtraCategory.parking),
  tripleGarage('Triple / 3-Car Garage', OutdoorExtraCategory.parking),
  carport('Carport', OutdoorExtraCategory.parking),
  extraOffStreetParking(
    'Extra Off-street Parking',
    OutdoorExtraCategory.parking,
  ),
  swimmingPool('Swimming Pool', OutdoorExtraCategory.outdoorLiving),
  splashPool('Splash Pool', OutdoorExtraCategory.outdoorLiving),
  patio('Patio / Covered Patio', OutdoorExtraCategory.outdoorLiving),
  stoep('Stoep', OutdoorExtraCategory.outdoorLiving),
  woodenDeck('Wooden Deck / Veranda', OutdoorExtraCategory.outdoorLiving),
  balcony('Balcony', OutdoorExtraCategory.outdoorLiving),
  lapa('Lapa / Entertainment Area', OutdoorExtraCategory.outdoorLiving),
  builtInBraai('Built-in Braai (Outdoor)', OutdoorExtraCategory.outdoorLiving),
  pizzaOven('Pizza Oven', OutdoorExtraCategory.outdoorLiving),
  garden('Garden', OutdoorExtraCategory.outdoorLiving),
  manicuredGarden('Manicured Garden', OutdoorExtraCategory.outdoorLiving),
  irrigationSystem('Irrigation System', OutdoorExtraCategory.outdoorLiving),
  courtyard('Courtyard', OutdoorExtraCategory.outdoorLiving),
  // From the myEdge listing form (2026-10). Stored by name, like the rest.
  heatedPool('Heated Pool', OutdoorExtraCategory.outdoorLiving),
  poolSafety('Pool Safety Net / Fence', OutdoorExtraCategory.outdoorLiving),
  communalPool('Communal Pool', OutdoorExtraCategory.outdoorLiving),
  landscapedGarden('Landscaped Garden', OutdoorExtraCategory.outdoorLiving),
  gardenService('Garden Service', OutdoorExtraCategory.outdoorLiving),
  waterFeature('Water Feature', OutdoorExtraCategory.outdoorLiving),
  gazebo('Gazebo', OutdoorExtraCategory.outdoorLiving),
  pavedDriveway('Paved Driveway', OutdoorExtraCategory.outdoorLiving),
  awning('Awning', OutdoorExtraCategory.outdoorLiving),
  flatlet('Flatlet / Garden Cottage', OutdoorExtraCategory.extraStructures),
  staffQuarters(
    'Staff / Domestic Quarters',
    OutdoorExtraCategory.extraStructures,
  ),
  workshop('Workshop / Storeroom', OutdoorExtraCategory.extraStructures),
  wendyHouse('Wendy House', OutdoorExtraCategory.extraStructures),
  studio('Studio', OutdoorExtraCategory.extraStructures),
  greenhouse('Greenhouse', OutdoorExtraCategory.extraStructures),
  outsideToilet('Outside Toilet', OutdoorExtraCategory.extraStructures),
  tennisCourt('Tennis Court', OutdoorExtraCategory.extraStructures),
  squashCourt('Squash Court', OutdoorExtraCategory.extraStructures),
  electricFencing('Electric Fencing', OutdoorExtraCategory.security),
  perimeterWall('Perimeter Wall', OutdoorExtraCategory.security),
  automatedGate('Automated Gate', OutdoorExtraCategory.security),
  alarmSystem('Alarm System', OutdoorExtraCategory.security),
  intercom('Intercom', OutdoorExtraCategory.security),
  cctv('CCTV / Cameras', OutdoorExtraCategory.security),
  boomedArea('Boomed Area / Security Estate', OutdoorExtraCategory.security),
  accessControl('24-Hour Access Control', OutdoorExtraCategory.security),
  guardhouse('Guardhouse', OutdoorExtraCategory.security),
  burglarBars('Burglar Bars', OutdoorExtraCategory.security),
  securityGates('Security Gates', OutdoorExtraCategory.security),
  armedResponse('24-Hour Armed Response', OutdoorExtraCategory.security),
  fullyFenced('Fully Fenced', OutdoorExtraCategory.security),
  partiallyFenced('Partially Fenced', OutdoorExtraCategory.security),
  solarPanels('Solar Panels', OutdoorExtraCategory.energyWater),
  inverter('Inverter / Backup Power', OutdoorExtraCategory.energyWater),
  batteryStorage('Battery Storage (Lithium)', OutdoorExtraCategory.energyWater),
  solarGeyser('Solar Geyser', OutdoorExtraCategory.energyWater),
  heatPumpGeyser('Heat Pump Geyser', OutdoorExtraCategory.energyWater),
  generator('Generator', OutdoorExtraCategory.energyWater),
  borehole('Borehole', OutdoorExtraCategory.energyWater),
  waterTanks('Water Tanks / JoJo Tanks', OutdoorExtraCategory.energyWater),
  rainwaterHarvesting('Rainwater Harvesting', OutdoorExtraCategory.energyWater),
  gasGeyser('Gas Geyser', OutdoorExtraCategory.energyWater),
  petFriendly('Pet Friendly', OutdoorExtraCategory.lifestyle),
  lift('Lift', OutdoorExtraCategory.lifestyle),
  sauna('Sauna', OutdoorExtraCategory.lifestyle),
  satelliteDish('Satellite Dish / TV Antenna', OutdoorExtraCategory.lifestyle),
  fibreInternet('Fibre Internet', OutdoorExtraCategory.lifestyle);

  final String displayString;
  final OutdoorExtraCategory category;

  const OutdoorExtra(this.displayString, this.category);

  static OutdoorExtra? fromString(String val) {
    for (final extra in OutdoorExtra.values) {
      if (extra.displayString.toLowerCase() == val.trim().toLowerCase()) {
        return extra;
      }
    }
    return null;
  }
}
