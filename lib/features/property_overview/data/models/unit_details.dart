/// The layout of a flatlet / garden cottage: a home of its own on the
/// property, so it has its own rooms, entrance, meter and often a tenant.
///
/// Kept on the one room (`ListingRoom.UnitDetails`, JSON) rather than as
/// separate rooms, so capturing a flatlet stays one tap and its bedrooms
/// never count as the main house's.
class UnitDetails {
  /// 0 is a bachelor flat (one open room to sleep and live in).
  final int bedrooms;
  final int bathrooms;
  final int kitchens;

  /// A kitchenette (sink, a plate or two) rather than a full kitchen.
  final bool kitchenette;
  final int lounges;
  final int otherRooms;
  final bool ownEntrance;
  final bool ownMeter;
  final bool parking;
  final bool letOut;

  /// Rand a month when [letOut].
  final String monthlyRent;

  const UnitDetails({
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.kitchens = 1,
    this.kitchenette = false,
    this.lounges = 0,
    this.otherRooms = 0,
    this.ownEntrance = false,
    this.ownMeter = false,
    this.parking = false,
    this.letOut = false,
    this.monthlyRent = '',
  });

  /// Room names that mean a flatlet, for rooms captured before the layout
  /// existed.
  static bool isFlatletName(String name) {
    final n = name.toLowerCase();
    return n.contains('flatlet') ||
        n.contains('cottage') ||
        n.contains('granny') ||
        n.contains('bachelor');
  }

  bool get isBachelor => bedrooms == 0;

  UnitDetails copyWith({
    int? bedrooms,
    int? bathrooms,
    int? kitchens,
    bool? kitchenette,
    int? lounges,
    int? otherRooms,
    bool? ownEntrance,
    bool? ownMeter,
    bool? parking,
    bool? letOut,
    String? monthlyRent,
  }) => UnitDetails(
    bedrooms: bedrooms ?? this.bedrooms,
    bathrooms: bathrooms ?? this.bathrooms,
    kitchens: kitchens ?? this.kitchens,
    kitchenette: kitchenette ?? this.kitchenette,
    lounges: lounges ?? this.lounges,
    otherRooms: otherRooms ?? this.otherRooms,
    ownEntrance: ownEntrance ?? this.ownEntrance,
    ownMeter: ownMeter ?? this.ownMeter,
    parking: parking ?? this.parking,
    letOut: letOut ?? this.letOut,
    monthlyRent: monthlyRent ?? this.monthlyRent,
  );

  factory UnitDetails.fromJson(Map<String, dynamic> j) {
    int i(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    bool b(String k) => j[k] as bool? ?? false;
    final rent = j['monthlyRent'];
    return UnitDetails(
      bedrooms: i('bedrooms', 1),
      bathrooms: i('bathrooms', 1),
      kitchens: i('kitchens', 1),
      kitchenette: b('kitchenette'),
      lounges: i('lounges', 0),
      otherRooms: i('otherRooms', 0),
      ownEntrance: b('ownEntrance'),
      ownMeter: b('ownMeter'),
      parking: b('parking'),
      letOut: b('letOut'),
      monthlyRent: rent == null
          ? ''
          : (rent is num ? rent.round().toString() : rent.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'kitchens': kitchens,
    'kitchenette': kitchenette,
    'lounges': lounges,
    'otherRooms': otherRooms,
    'ownEntrance': ownEntrance,
    'ownMeter': ownMeter,
    'parking': parking,
    'letOut': letOut,
    if (letOut && double.tryParse(monthlyRent.trim()) != null)
      'monthlyRent': double.parse(monthlyRent.trim()),
  };

  /// "Bachelor flat · 1 bathroom", for the room list.
  String get shortSummary => [
    isBachelor
        ? 'Bachelor flat'
        : '$bedrooms bedroom${bedrooms == 1 ? '' : 's'}',
    if (bathrooms > 0) '$bathrooms bathroom${bathrooms == 1 ? '' : 's'}',
    if (letOut) 'let out',
  ].join(' · ');

  /// "Bachelor flat, 1 bath, kitchenette, own entrance, let at R 6 500 a
  /// month" — for the room list, the inspection page and the cover facts.
  /// [money] formats the rent (the report's Rand style).
  String summary({String Function(num)? money}) {
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
    final rent = double.tryParse(monthlyRent.trim());
    return [
      isBachelor ? 'Bachelor flat' : count(bedrooms, 'bedroom', 'bedrooms'),
      if (bathrooms > 0) count(bathrooms, 'bathroom', 'bathrooms'),
      if (kitchens > 0)
        kitchenette
            ? (kitchens == 1 ? 'kitchenette' : '$kitchens kitchenettes')
            : count(kitchens, 'kitchen', 'kitchens'),
      if (lounges > 0) count(lounges, 'lounge', 'lounges'),
      if (otherRooms > 0) count(otherRooms, 'other room', 'other rooms'),
      if (ownEntrance) 'own entrance',
      if (ownMeter) 'own electricity meter',
      if (parking) 'parking',
      if (letOut)
        rent == null
            ? 'let out'
            : 'let at ${money?.call(rent) ?? 'R ${rent.round()}'} a month',
    ].join(', ');
  }
}
