// "Area details" (GET /api/property/area) and homes for sale nearby
// (GET /api/property/{municipality}/{erf}/for-sale). Every block is optional:
// the API leaves one out when its source is down.

double? _d(Object? v) => (v as num?)?.toDouble();
int? _i(Object? v) => (v as num?)?.toInt();

class Climate {
  final double meanC;
  final double avgMaxC;
  final double avgMinC;
  final double annualRainMm;
  final String hottestMonth;
  final double hottestAvgMaxC;
  final String coldestMonth;
  final double coldestAvgMinC;
  final String years;
  final String source;
  final double? humidityPct;

  const Climate({
    required this.meanC,
    required this.avgMaxC,
    required this.avgMinC,
    required this.annualRainMm,
    required this.hottestMonth,
    required this.hottestAvgMaxC,
    required this.coldestMonth,
    required this.coldestAvgMinC,
    required this.years,
    required this.source,
    this.humidityPct,
  });

  static Climate? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : Climate(
          meanC: _d(j['meanC']) ?? 0,
          avgMaxC: _d(j['avgMaxC']) ?? 0,
          avgMinC: _d(j['avgMinC']) ?? 0,
          annualRainMm: _d(j['annualRainMm']) ?? 0,
          hottestMonth: j['hottestMonth'] as String? ?? '',
          hottestAvgMaxC: _d(j['hottestAvgMaxC']) ?? 0,
          coldestMonth: j['coldestMonth'] as String? ?? '',
          coldestAvgMinC: _d(j['coldestAvgMinC']) ?? 0,
          years: j['years'] as String? ?? '',
          source: j['source'] as String? ?? '',
          humidityPct: _d(j['humidityPct']),
        );
}

class Population {
  final String? mainPlace;
  final String? subPlace;
  final int? population;
  final int? households;
  final double? areaKm2;
  final double? peoplePerKm2;
  final String municipality;
  final String year;
  final String source;

  /// A more recent estimate for the same sub place (WorldPop).
  final int? estimatedPopulation;
  final String? estimateYear;
  final String? estimateSource;

  const Population({
    this.mainPlace,
    this.subPlace,
    this.population,
    this.households,
    this.areaKm2,
    this.peoplePerKm2,
    required this.municipality,
    required this.year,
    required this.source,
    this.estimatedPopulation,
    this.estimateYear,
    this.estimateSource,
  });

  static Population? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : Population(
          mainPlace: j['mainPlace'] as String?,
          subPlace: j['subPlace'] as String?,
          population: _i(j['population']),
          households: _i(j['households']),
          areaKm2: _d(j['areaKm2']),
          peoplePerKm2: _d(j['peoplePerKm2']),
          municipality: j['municipality'] as String? ?? '',
          year: j['year'] as String? ?? '',
          source: j['source'] as String? ?? '',
          estimatedPopulation: _i(j['estimatedPopulation']),
          estimateYear: j['estimateYear'] as String?,
          estimateSource: j['estimateSource'] as String?,
        );
}

class IncomeBand {
  final String label;
  final double percent;
  const IncomeBand(this.label, this.percent);
}

class HouseholdIncome {
  final String municipality;
  final List<IncomeBand> bands;
  final String medianBand;
  final String year;
  final String source;

  const HouseholdIncome({
    required this.municipality,
    required this.bands,
    required this.medianBand,
    required this.year,
    required this.source,
  });

  static HouseholdIncome? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : HouseholdIncome(
          municipality: j['municipality'] as String? ?? '',
          bands: [
            for (final b in (j['bands'] as List? ?? const []))
              IncomeBand(b['label'] as String? ?? '', _d(b['percent']) ?? 0),
          ],
          medianBand: j['medianBand'] as String? ?? '',
          year: j['year'] as String? ?? '',
          source: j['source'] as String? ?? '',
        );
}

class CrimeCount {
  final String crime;
  final int count;
  final int previousCount;
  const CrimeCount(this.crime, this.count, this.previousCount);
}

class CrimeStats {
  final String precinct;
  final int? population;
  final String period;
  final String previousPeriod;
  final List<CrimeCount> crimes;
  final int total;
  final int previousTotal;
  final double? totalPer100k;

  /// Against every precinct in the country: Very low … Very high.
  final String? band;
  final String source;

  const CrimeStats({
    required this.precinct,
    this.population,
    required this.period,
    required this.previousPeriod,
    required this.crimes,
    required this.total,
    required this.previousTotal,
    this.totalPer100k,
    this.band,
    required this.source,
  });

  /// The change on the previous 12 months, as a percentage.
  double? get change =>
      previousTotal == 0 ? null : (total - previousTotal) / previousTotal * 100;

  static CrimeStats? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : CrimeStats(
          precinct: j['precinct'] as String? ?? '',
          population: _i(j['population']),
          period: j['period'] as String? ?? '',
          previousPeriod: j['previousPeriod'] as String? ?? '',
          crimes: [
            for (final c in (j['crimes'] as List? ?? const []))
              CrimeCount(
                c['crime'] as String? ?? '',
                _i(c['count']) ?? 0,
                _i(c['previousCount']) ?? 0,
              ),
          ],
          total: _i(j['total']) ?? 0,
          previousTotal: _i(j['previousTotal']) ?? 0,
          totalPer100k: _d(j['totalPer100k']),
          band: j['band'] as String?,
          source: j['source'] as String? ?? '',
        );
}

class AreaDetails {
  final Climate? climate;
  final Population? population;
  final HouseholdIncome? income;
  final CrimeStats? crime;

  const AreaDetails({this.climate, this.population, this.income, this.crime});

  bool get isEmpty =>
      climate == null && population == null && income == null && crime == null;

  factory AreaDetails.fromJson(Map<String, dynamic> j) => AreaDetails(
    climate: Climate.fromJson(j['climate'] as Map<String, dynamic>?),
    population: Population.fromJson(j['population'] as Map<String, dynamic>?),
    income: HouseholdIncome.fromJson(j['income'] as Map<String, dynamic>?),
    crime: CrimeStats.fromJson(j['crime'] as Map<String, dynamic>?),
  );
}

/// A home for sale on Property24, shown as Property24's and linked to it.
class ForSaleListing {
  final String listingNumber;
  final String url;
  final double? priceZar;
  final String title;
  final String? suburb;
  final String? address;
  final String? excerpt;
  final int? bedrooms;
  final double? bathrooms;
  final int? parking;
  final double? floorM2;
  final double? erfM2;
  final String? imageUrl;
  final DateTime? listedOn;

  /// How far from the property, when both are placed on the map.
  final double? distanceM;

  const ForSaleListing({
    required this.listingNumber,
    required this.url,
    this.priceZar,
    required this.title,
    this.suburb,
    this.address,
    this.excerpt,
    this.bedrooms,
    this.bathrooms,
    this.parking,
    this.floorM2,
    this.erfM2,
    this.imageUrl,
    this.listedOn,
    this.distanceM,
  });

  factory ForSaleListing.fromJson(Map<String, dynamic> j) => ForSaleListing(
    listingNumber: j['listingNumber'] as String? ?? '',
    url: j['url'] as String? ?? '',
    priceZar: _d(j['priceZar']),
    title: j['title'] as String? ?? '',
    suburb: j['suburb'] as String?,
    address: j['address'] as String?,
    excerpt: j['excerpt'] as String?,
    bedrooms: _i(j['bedrooms']),
    bathrooms: _d(j['bathrooms']),
    parking: _i(j['parking']),
    floorM2: _d(j['floorM2']),
    erfM2: _d(j['erfM2']),
    imageUrl: j['imageUrl'] as String?,
    listedOn: DateTime.tryParse(j['listedOn'] as String? ?? ''),
    distanceM: _d(j['distanceM']),
  );
}

class ForSaleSuburb {
  final int id;
  final String name;
  final String town;
  final String url;
  const ForSaleSuburb(this.id, this.name, this.town, this.url);
}

class ForSale {
  final String source;
  final String attribution;
  final List<ForSaleSuburb> suburbs;
  final List<ForSaleListing> listings;

  const ForSale({
    required this.source,
    required this.attribution,
    this.suburbs = const [],
    this.listings = const [],
  });

  factory ForSale.fromJson(Map<String, dynamic> j) => ForSale(
    source: j['source'] as String? ?? 'Property24',
    attribution: j['attribution'] as String? ?? '',
    suburbs: [
      for (final s in (j['suburbs'] as List? ?? const []))
        ForSaleSuburb(
          (s['id'] as num).toInt(),
          s['name'] as String? ?? '',
          s['town'] as String? ?? '',
          s['url'] as String? ?? '',
        ),
    ],
    listings: [
      for (final l in (j['listings'] as List? ?? const []))
        ForSaleListing.fromJson(l as Map<String, dynamic>),
    ],
  );
}
