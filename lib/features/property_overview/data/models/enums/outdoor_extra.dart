enum OutdoorExtraCategory {
  parking,
  outdoorLiving,
  extraStructures,
  security,
  energyWater,
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
  manicuredGarden('Manicured Garden', OutdoorExtraCategory.outdoorLiving),
  irrigationSystem('Irrigation System', OutdoorExtraCategory.outdoorLiving),
  courtyard('Courtyard', OutdoorExtraCategory.outdoorLiving),
  flatlet('Flatlet / Garden Cottage', OutdoorExtraCategory.extraStructures),
  staffQuarters(
    'Staff / Domestic Quarters',
    OutdoorExtraCategory.extraStructures,
  ),
  workshop('Workshop / Storeroom', OutdoorExtraCategory.extraStructures),
  wendyHouse('Wendy House', OutdoorExtraCategory.extraStructures),
  electricFencing('Electric Fencing', OutdoorExtraCategory.security),
  perimeterWall('Perimeter Wall', OutdoorExtraCategory.security),
  automatedGate('Automated Gate', OutdoorExtraCategory.security),
  alarmSystem('Alarm System', OutdoorExtraCategory.security),
  cctv('CCTV / Cameras', OutdoorExtraCategory.security),
  boomedArea('Boomed Area / Security Estate', OutdoorExtraCategory.security),
  accessControl('24-Hour Access Control', OutdoorExtraCategory.security),
  guardhouse('Guardhouse', OutdoorExtraCategory.security),
  solarPanels('Solar Panels', OutdoorExtraCategory.energyWater),
  inverter('Inverter / Backup Power', OutdoorExtraCategory.energyWater),
  batteryStorage('Battery Storage (Lithium)', OutdoorExtraCategory.energyWater),
  solarGeyser('Solar Geyser', OutdoorExtraCategory.energyWater),
  heatPumpGeyser('Heat Pump Geyser', OutdoorExtraCategory.energyWater),
  generator('Generator', OutdoorExtraCategory.energyWater),
  borehole('Borehole', OutdoorExtraCategory.energyWater),
  waterTanks('Water Tanks / JoJo Tanks', OutdoorExtraCategory.energyWater),
  rainwaterHarvesting('Rainwater Harvesting', OutdoorExtraCategory.energyWater),
  gasGeyser('Gas Geyser', OutdoorExtraCategory.energyWater);

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
