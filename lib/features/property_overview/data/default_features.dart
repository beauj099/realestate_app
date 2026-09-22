/// Pre-checked features for a newly added room, keyed by `roomTypeId`
/// (`RoomCategory.index + 1`): 1 bedroom, 2 bathroom, 3 living, 4 kitchen,
/// 5 work & study, 6 entertainment. 7 (additional) intentionally has no
/// defaults — those rooms are too diverse to presume. Every entry must stay
/// within that room's `StandardAmenity.relevantForRoomTypeId` set, otherwise
/// the room opens with a checked item from another room's section.
const Map<int, List<String>> roomDefaultFeatures = {
  1: [
    'Walk-in Closet',
    'En-suite Bathroom',
    'Ceiling Fan',
    'Tiled Floors',
    'Wooden / Laminate Floors',
  ],
  2: ['Tiled Floors', 'Underfloor Heating'],
  3: [
    'Fireplace',
    'Underfloor Heating',
    'Air Conditioning',
    'Tiled Floors',
    'Wooden / Laminate Floors',
    'High Ceilings / Exposed Beams / Exposed Trusses',
  ],
  4: [
    'Built-in Cupboards',
    'Granite / Stone Countertops',
    'Gas Hob',
    'Eye-level Oven',
    'Extractor Fan',
    'Dishwasher Connection',
    'Breakfast Nook',
  ],
  5: ['Fibre Ready / Fibre Installed', 'Air Conditioning', 'Tiled Floors'],
  6: [
    'Built-in Braai',
    'Built-in Bar',
    'Air Conditioning',
    'High Ceilings / Exposed Beams / Exposed Trusses',
  ],
};

const List<String> outdoorDefaultFeatures = [
  'Single Garage',
  'Patio / Covered Patio',
  'Manicured Garden',
  'Perimeter Wall',
  'Automated Gate',
];
