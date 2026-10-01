import '../../property_overview/data/models/enums/condition_rating.dart';
import '../../property_overview/data/models/enums/room_category.dart';
import '../../property_overview/data/models/property_state.dart';
import '../data/models/property_report.dart' show rand;
import 'report_pack_pdf.dart';

/// The cover's "Property portfolio": what the agent captured about the home.
List<String> packPortfolio(PropertyState s) {
  int count(RoomCategory c) => s.rooms
      .where(
        (r) => RoomCategoryExtension.categoryForRoomTypeId(r.roomTypeId) == c,
      )
      .length;
  bool named(String word) =>
      s.rooms.any((r) => r.name.toLowerCase().contains(word));
  String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

  final bedrooms = count(RoomCategory.bedroom);
  final bathrooms = count(RoomCategory.bathroom);
  final ensuites = s.rooms
      .where(
        (r) =>
            r.name.toLowerCase().contains('en-suite') ||
            r.name.toLowerCase().contains('ensuite'),
      )
      .length;
  final living = count(RoomCategory.livingSpaces);
  final parking = s.parking.fold<int>(0, (n, p) => n + p.quantity);
  final floor = double.tryParse(s.floorArea.replaceAll(',', '.'));
  final year = int.tryParse(s.constructionYear.trim());

  return [
    if (floor != null && floor > 0) 'Floor area: ${floor.round()} m²',
    if (year != null && year > 1800) 'Built in $year',
    if (bedrooms > 0 || bathrooms > 0)
      [
        if (bedrooms > 0) plural(bedrooms, 'bedroom', 'bedrooms'),
        if (bathrooms > 0)
          '${plural(bathrooms, 'bathroom', 'bathrooms')}${ensuites > 0 ? ' ($ensuites en-suite)' : ''}',
      ].join(', '),
    if (living > 0) plural(living, 'living area', 'living areas'),
    if (named('kitchen'))
      'Kitchen${named('pantry') ? ' + pantry' : ''}${named('scullery') ? ' + scullery' : ''}',
    if (named('study') || named('office')) 'Study / office',
    // A flatlet with its layout captured is described; else just named.
    for (final r in s.rooms)
      if (r.unit case final unit?) 'Flatlet: ${unit.summary(money: rand)}',
    if (!s.rooms.any((r) => r.unit != null) &&
        (named('flatlet') || named('granny') || named('cottage')))
      'Flatlet',
    if (parking > 0) plural(parking, 'parking bay', 'parking bays'),
    if (s.outdoorFeatures.isNotEmpty) s.outdoorFeatures.take(8).join(', '),
  ];
}

/// The agent's inspection for the pack: every room captured, with its
/// condition, score, features and notes; the home as a whole; outside.
/// Empty when no rooms were captured.
PackInspection packInspection(PropertyState s) {
  final outside = s.outdoorFeatures.take(8).join(', ');
  return PackInspection(
    rooms: [
      for (final r in s.rooms)
        PackRoom(
          name: r.name.trim().isEmpty ? 'Room' : r.name.trim(),
          condition: ConditionRating.fromStored(r.conditionRating)?.label ?? '',
          conditionLevel: ConditionRating.fromStored(r.conditionRating)?.level,
          score: r.score,
          features: [
            for (final f in r.features)
              if (!r.hiddenFeatures.contains(f.description)) f.description,
          ],
          // A flatlet's layout leads its notes.
          notes: [
            if (r.unit case final unit?) '${unit.summary(money: rand)}.',
            if (r.notes.trim().isNotEmpty) r.notes.trim(),
          ].join(' '),
        ),
    ],
    houseScore: s.houseScore,
    building: [
      for (final line in packPortfolio(s))
        if (line != outside) line,
    ],
    outside: s.outdoorFeatures,
  );
}

/// When the owners bought, from the listing's valuation; null unless both
/// the month and the price were captured.
({DateTime date, double priceZar})? packOwnersPurchase(PropertyState s) {
  final date = s.listingValuation.lastPurchaseDate;
  final price = double.tryParse(
    s.listingValuation.lastPurchasePrice.replaceAll(RegExp(r'[\s,]'), ''),
  );
  return date == null || price == null || price <= 0
      ? null
      : (date: date, priceZar: price);
}

/// The owners as the pack names them — "Piet & Mary Swanepoel" when they
/// share a surname, "Bill Murray & John Smith" when not — and the letter's
/// greeting: by title when every owner has one ("Mr & Mrs Swanepoel"), else
/// by first name ("Piet & Mary"). Agents can change both.
(String preparedFor, String greeting) packOwners(PropertyState s) {
  final owners = [s.primaryContact, ...s.coContacts]
      .map(
        (c) => (
          name: c.companyName.trim().isNotEmpty && c.fullName.trim().isEmpty
              ? c.companyName.trim()
              : c.fullName.trim(),
          title: c.title.trim(),
        ),
      )
      .where((o) => o.name.isNotEmpty)
      .toList();
  final names = [for (final o in owners) o.name];
  return (
    joinOwnerNames(names),
    greetOwners([for (final o in owners) (title: o.title, name: o.name)]),
  );
}

/// "Mr & Mrs Swanepoel", "Mr Murray & Dr Smith" when every owner has a
/// title; else their first names, "Piet & Mary".
String greetOwners(List<({String title, String name})> owners) {
  if (owners.isNotEmpty && owners.every((o) => o.title.isNotEmpty)) {
    final surnames = [for (final o in owners) splitName(o.name).last];
    final shared =
        surnames.first.isNotEmpty &&
        surnames.every((n) => n.toLowerCase() == surnames.first.toLowerCase());
    return shared
        ? '${joinWithAnd([for (final o in owners) o.title])} ${surnames.first}'
        : joinWithAnd([
            for (final o in owners)
              '${o.title} ${splitName(o.name).last}'.trim(),
          ]);
  }
  return joinWithAnd([for (final o in owners) splitName(o.name).first]);
}

/// "A", "A & B", "A, B & C".
String joinWithAnd(List<String> parts) => parts.length <= 1
    ? parts.join()
    : '${parts.sublist(0, parts.length - 1).join(', ')} & ${parts.last}';

/// Owners' full names for the cover: a shared surname is said once.
String joinOwnerNames(List<String> names) {
  if (names.length < 2) return joinWithAnd(names);
  final split = names.map(splitName).toList();
  final surname = split.first.last.toLowerCase();
  final shared =
      surname.isNotEmpty &&
      split.every((n) => n.first.isNotEmpty && n.last.toLowerCase() == surname);
  return shared
      ? '${joinWithAnd([for (final n in split) n.first])} ${split.first.last}'
      : joinWithAnd(names);
}

/// Surname particles, so "Francois du Toit" has the surname "du Toit".
const _particles = {
  'van',
  'der',
  'den',
  'du',
  'de',
  'le',
  'la',
  'von',
  'ten',
  'ter',
  'te',
  'vd',
};

/// A full name as (first names, surname): "Mary Anne van der Merwe" →
/// ("Mary Anne", "van der Merwe"). One word is a first name only.
({String first, String last}) splitName(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.length < 2) return (first: words.join(), last: '');
  var at = words.length - 1;
  for (var i = 1; i < words.length - 1; i++) {
    if (_particles.contains(words[i].toLowerCase())) {
      at = i;
      break;
    }
  }
  return (
    first: words.sublist(0, at).join(' '),
    last: words.sublist(at).join(' '),
  );
}

/// The numbers the cover shows as icons.
class PackFacts {
  final int bedrooms;

  /// A guest toilet counts as half: "4.5".
  final double bathrooms;

  /// Cars that fit in garages, and other bays (carports, open parking).
  final int garages;
  final int parking;
  final double? floorM2;
  final double? erfM2;
  final int? yearBuilt;
  final bool pool;
  final bool garden;
  final bool fibre;
  final bool borehole;
  final bool backupPower;
  final bool flatlet;
  final bool petFriendly;

  const PackFacts({
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.garages = 0,
    this.parking = 0,
    this.floorM2,
    this.erfM2,
    this.yearBuilt,
    this.pool = false,
    this.garden = false,
    this.fibre = false,
    this.borehole = false,
    this.backupPower = false,
    this.flatlet = false,
    this.petFriendly = false,
  });

  /// Features shown as an icon and a name (no number), as property portals
  /// do: (icon key, name).
  List<(String, String)> get extras => [
    if (pool) ('pool', 'Pool'),
    if (flatlet) ('flatlet', 'Flatlet'),
    if (garden) ('garden', 'Garden'),
    if (fibre) ('fibre', 'Fibre internet'),
    if (borehole) ('borehole', 'Borehole'),
    if (backupPower) ('backup', 'Backup power'),
    if (petFriendly) ('pets', 'Pet friendly'),
  ];
}

/// What the agent captured, as the cover's facts. [parkingTypes] names each
/// parking type ("Double Garage"), so garages count cars.
PackFacts packFacts(PropertyState s, Map<int, String> parkingTypes) {
  var bathrooms = 0.0;
  var bedrooms = 0;
  for (final r in s.rooms) {
    switch (RoomCategoryExtension.categoryForRoomTypeId(r.roomTypeId)) {
      case RoomCategory.bedroom:
        bedrooms++;
      case RoomCategory.bathroom:
        final name = r.name.toLowerCase();
        bathrooms += name.contains('toilet') || name.contains('powder')
            ? 0.5
            : 1;
      default:
        break;
    }
  }
  var garages = 0;
  var parking = 0;
  for (final p in s.parking) {
    final name = (parkingTypes[p.parkingTypeId] ?? '').toLowerCase();
    if (name.contains('garage')) {
      final perGarage = name.contains('triple')
          ? 3
          : name.contains('double')
          ? 2
          : 1;
      garages += perGarage * p.quantity;
    } else {
      parking += p.quantity;
    }
  }
  double? size(String v) {
    final n = double.tryParse(v.replaceAll(RegExp(r'[\s,]'), ''));
    return n != null && n > 0 ? n : null;
  }

  final year = int.tryParse(s.constructionYear.trim());
  // What the agent ticked, anywhere: outside features, rooms and their items.
  final ticked = [
    ...s.outdoorFeatures,
    for (final r in s.rooms) ...[
      r.name,
      for (final f in r.features) f.description,
    ],
  ].map((t) => t.toLowerCase()).toList();
  bool any(bool Function(String t) test) => ticked.any(test);
  return PackFacts(
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    garages: garages,
    parking: parking,
    floorM2: size(s.floorArea),
    erfM2: size(s.erfSize),
    yearBuilt: year != null && year > 1800 ? year : null,
    pool: any((t) => t.contains('pool')),
    garden: any(
      (t) =>
          t.contains('garden') &&
          !t.contains('cottage') &&
          !t.contains('garden room'),
    ),
    fibre: any((t) => t.contains('fibre') || t.contains('fiber')),
    borehole: any((t) => t.contains('borehole') || t.contains('wellpoint')),
    backupPower: any(
      (t) =>
          t.contains('inverter') ||
          t.contains('solar panel') ||
          t.contains('backup') ||
          t.contains('generator'),
    ),
    flatlet:
        s.rooms.any((r) => r.unit != null) ||
        any(
          (t) =>
              t.contains('flatlet') ||
              t.contains('granny') ||
              t.contains('cottage'),
        ),
    petFriendly: any((t) => t.contains('pet friendly')),
  );
}

/// Photos for the cover's row of three, after the main photo: the other
/// outside photos, then the cover photos of the rooms buyers look at first.
List<String> packGallery(PropertyState s, {int count = 3}) {
  const order = [
    RoomCategory.livingSpaces,
    RoomCategory.kitchenAndUtility,
    RoomCategory.entertainment,
    RoomCategory.bedroom,
    RoomCategory.bathroom,
  ];
  final rooms = [...s.rooms]
    ..sort((a, b) {
      int rank(int typeId) {
        final i = order.indexOf(
          RoomCategoryExtension.categoryForRoomTypeId(typeId),
        );
        return i < 0 ? order.length : i;
      }

      return rank(a.roomTypeId).compareTo(rank(b.roomTypeId));
    });
  return [
    ...s.exteriorPhotos.skip(1),
    for (final r in rooms)
      if (r.photos.isNotEmpty) r.photos.first.path,
  ].take(count).toList();
}

/// "Unit 5, 10 Bosman Street" and "Strand, Cape Town" for the cover.
(String street, String area) packAddress(PropertyState s) {
  final street = [
    if (s.unitNumber.trim().isNotEmpty) 'Unit ${s.unitNumber.trim()},',
    s.streetNumber.trim(),
    s.street.trim(),
  ].where((p) => p.isNotEmpty).join(' ');
  final area = [
    s.suburb.trim(),
    s.city.trim(),
  ].where((p) => p.isNotEmpty).toSet().join(', ');
  return (street, area);
}

/// Zoning in words for owners who do not know the codes: "Residential 1 :
/// Conventional Housing" → "Residential 1 (Conventional Housing)"; the code
/// ("R1") only when there is no description.
String? readableZoning(String? code, String? description) {
  final d = (description ?? '').trim();
  if (d.isEmpty) return (code ?? '').trim().isEmpty ? null : code!.trim();
  final parts = d.split(':');
  final main = parts.first.trim();
  final detail = parts.skip(1).join(':').trim();
  return detail.isEmpty ? main : '$main ($detail)';
}
