/// What a suggestion is: a numbered erf from City records ([property]), a
/// numbered house from OpenStreetMap ([address]), a street (a number typed
/// with it is the agent's, not on record), a suburb or town ([area]), or a
/// complex or estate.
enum SuggestionKind { property, address, street, area, estate }

/// An address offered while the agent types. It comes from two searches the
/// app runs at once: `GET /api/property/suggest` (the Cape Town and
/// Johannesburg parcel records, fast) and `…/suggest/national` (OpenStreetMap
/// for the whole country, a few seconds). [mergeSuggestions] combines them.
class AddressSuggestion {
  final SuggestionKind kind;

  /// The two lines shown: "Unit 5, 10 Bosman Street" / "Strand, Cape Town".
  final String title;
  final String subtitle;

  final String label;
  final String? unit;
  final String? streetNumber;
  final String streetName;
  final String suburb;
  final String city;
  final String province;
  final String country;
  final String? postalCode;
  final String? erf;
  final double? lat;
  final double? lng;

  /// The number is on record for this address (not only typed by the agent).
  final bool numberVerified;

  /// "City records" or "OpenStreetMap" (whose licence asks for credit).
  final String source;

  /// How well it fits what was typed, on one scale for both searches.
  final double rank;

  /// The same for the same place from either search.
  final String key;

  const AddressSuggestion({
    required this.kind,
    required this.title,
    required this.streetName,
    required this.suburb,
    required this.city,
    required this.province,
    required this.country,
    this.subtitle = '',
    this.label = '',
    this.unit,
    this.streetNumber,
    this.postalCode,
    this.erf,
    this.lat,
    this.lng,
    this.numberVerified = false,
    this.source = '',
    this.rank = 0,
    this.key = '',
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> j) {
    String? text(String k) {
      final v = (j[k] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final label = text('label') ?? '';
    return AddressSuggestion(
      kind: SuggestionKind.values.firstWhere(
        (k) => k.name == j['kind'],
        orElse: () => text('erf') != null
            ? SuggestionKind.property
            : SuggestionKind.street,
      ),
      title: text('title') ?? label,
      subtitle: text('subtitle') ?? '',
      label: label,
      unit: text('unit'),
      streetNumber: text('streetNumber'),
      streetName: text('streetName') ?? '',
      suburb: text('suburb') ?? '',
      city: text('city') ?? '',
      province: text('province') ?? '',
      country: text('country') ?? '',
      postalCode: text('postalCode'),
      erf: text('erf'),
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      numberVerified: j['numberVerified'] as bool? ?? false,
      source: text('source') ?? '',
      rank: (j['rank'] as num?)?.toDouble() ?? 0,
      key: text('key') ?? '${j['kind']} $label'.toLowerCase(),
    );
  }

  /// A numbered address, i.e. one erf — not just a street.
  bool get isProperty => kind == SuggestionKind.property;

  /// Somewhere a property is (suburb, town, complex), not an address.
  bool get isArea =>
      kind == SuggestionKind.area || kind == SuggestionKind.estate;

  bool get fromOpenStreetMap => source == 'OpenStreetMap';
}

/// The two searches as one list, the way the API orders each: best first, one
/// of each place, at most two areas, and nothing far behind the best. Streets
/// and areas that fit about as well alternate, so "bosm" shows Bosman Street
/// and Bosmont side by side rather than every area first.
List<AddressSuggestion> mergeSuggestions(
  Iterable<AddressSuggestion> a,
  Iterable<AddressSuggestion> b, {
  int limit = 6,
}) {
  const maxAreas = 2;
  const maxBehindBest = 30.0;
  const clearly = 3.0;

  final byKey = <String, AddressSuggestion>{};
  for (final s in [...a, ...b]) {
    final seen = byKey[s.key];
    if (seen == null || s.rank > seen.rank) byKey[s.key] = s;
  }
  final sorted = byKey.values.toList()
    ..sort((x, y) {
      final r = y.rank.compareTo(x.rank);
      return r != 0 ? r : x.title.compareTo(y.title);
    });
  if (sorted.isEmpty) return const [];

  final best = sorted.first.rank;
  final good = sorted.where((s) => s.rank >= best - maxBehindBest);
  final places = good.where((s) => !s.isArea).toList();
  final areas = good.where((s) => s.isArea).take(maxAreas).toList();

  final list = <AddressSuggestion>[];
  var lastWasArea = true; // a tie at the top goes to the street
  while (list.length < limit && (places.isNotEmpty || areas.isNotEmpty)) {
    final bool takeArea;
    if (places.isEmpty) {
      takeArea = true;
    } else if (areas.isEmpty) {
      takeArea = false;
    } else {
      final gap = areas.first.rank - places.first.rank;
      takeArea = gap > clearly || (gap > -clearly && !lastWasArea);
    }
    list.add(takeArea ? areas.removeAt(0) : places.removeAt(0));
    lastWasArea = takeArea;
  }
  return list;
}
