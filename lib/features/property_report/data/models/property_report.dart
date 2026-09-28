import 'dart:math' as math;

// The property report the API assembles from public municipal data
// (`GET /api/property/{municipality}/{erf}`): site, buildings, municipal value,
// suburb trend and filtered comparable sales.
//
// Two licence rules travel with the data rather than living in the UI:
//   * ImageryRef.allowedInPrint comes from the server. The PDF export only uses
//     [PropertyReport.printableImagery]; Street View is screen-only.
//   * Imagery is always shown with its attribution next to it, uncropped.

import 'agent_sales.dart';

double? _d(Object? v) => (v as num?)?.toDouble();

/// One property the address resolved to.
class PropertyCandidate {
  final String municipality;
  final String erf;
  final String? sg26;
  final String suburb;
  final String township;

  const PropertyCandidate({
    required this.municipality,
    required this.erf,
    required this.suburb,
    required this.township,
    this.sg26,
  });

  factory PropertyCandidate.fromJson(Map<String, dynamic> j) =>
      PropertyCandidate(
        municipality: j['municipality'] as String,
        erf: j['erf'] as String,
        sg26: j['sg26'] as String?,
        suburb: (j['suburb'] ?? '') as String,
        township: (j['township'] ?? '') as String,
      );

  String get label => 'Erf $erf, ${_title(suburb)}';
}

class ImageryRef {
  final String kind;
  final String url;
  final String attribution;
  final bool allowedInPrint;

  const ImageryRef({
    required this.kind,
    required this.url,
    required this.attribution,
    required this.allowedInPrint,
  });

  factory ImageryRef.fromJson(Map<String, dynamic> j) => ImageryRef(
    kind: j['kind'] as String,
    url: j['url'] as String,
    attribution: j['attribution'] as String,
    allowedInPrint: j['allowedInPrint'] as bool? ?? false,
  );

  String get title => kind == 'streetview' ? 'Street view' : 'Satellite view';
}

/// A recorded sale near the property. Named to avoid dart:core's Comparable.
class ComparableSale {
  final String address;
  final String? erf;
  final double erfExtentM2;
  final double dwellingExtentM2;
  final DateTime saleDate;
  final double salePriceZar;
  final double? indexedPriceZar;
  final double? pricePerDwellingM2;
  final bool included;
  final String? excludedBecause;

  /// How far from the subject, when the source gives locations.
  final double? distanceM;
  final double? lat;
  final double? lng;

  const ComparableSale({
    required this.address,
    required this.erfExtentM2,
    required this.dwellingExtentM2,
    required this.saleDate,
    required this.salePriceZar,
    required this.included,
    this.erf,
    this.indexedPriceZar,
    this.pricePerDwellingM2,
    this.excludedBecause,
    this.distanceM,
    this.lat,
    this.lng,
  });

  factory ComparableSale.fromJson(Map<String, dynamic> j) => ComparableSale(
    address: j['address'] as String,
    erf: j['erf'] as String?,
    erfExtentM2: _d(j['erfExtentM2']) ?? 0,
    dwellingExtentM2: _d(j['dwellingExtentM2']) ?? 0,
    saleDate: DateTime.parse(j['saleDate'] as String),
    salePriceZar: _d(j['salePriceZar']) ?? 0,
    indexedPriceZar: _d(j['indexedPriceZar']),
    pricePerDwellingM2: _d(j['pricePerDwellingM2']),
    included: j['included'] as bool? ?? false,
    excludedBecause: j['excludedBecause'] as String?,
    distanceM: _d(j['distanceM']),
    lat: _d(j['lat']),
    lng: _d(j['lng']),
  );
}

class Building {
  final double roofM2;
  final double? heightM;
  final int? estimatedStoreys;
  final String? capturedPeriod;

  const Building({
    required this.roofM2,
    this.heightM,
    this.estimatedStoreys,
    this.capturedPeriod,
  });

  factory Building.fromJson(Map<String, dynamic> j) => Building(
    roofM2: _d(j['roofM2']) ?? 0,
    heightM: _d(j['heightM']),
    estimatedStoreys: j['estimatedStoreys'] as int?,
    capturedPeriod: j['capturedPeriod'] as String?,
  );
}

class ApprovedWork {
  final String? date;
  final String? description;
  final String? category;
  final double? areaM2;
  final double? valueZar;

  const ApprovedWork({
    this.date,
    this.description,
    this.category,
    this.areaM2,
    this.valueZar,
  });

  factory ApprovedWork.fromJson(Map<String, dynamic> j) => ApprovedWork(
    date: j['approvalDate'] as String?,
    description: j['description'] as String?,
    category: j['category'] as String?,
    areaM2: _d(j['areaM2']),
    valueZar: _d(j['valueZar']),
  );
}

/// The suburb's median values on the last two municipal rolls.
class SuburbStats {
  final String name;
  final int residentialCount;
  final double medianLandM2;
  final double medianBuildingM2;
  final double gv2022;
  final double gv2025;
  final double growthPercent;
  final double annualGrowthPercent;

  const SuburbStats({
    required this.name,
    required this.residentialCount,
    required this.medianLandM2,
    required this.medianBuildingM2,
    required this.gv2022,
    required this.gv2025,
    required this.growthPercent,
    required this.annualGrowthPercent,
  });

  factory SuburbStats.fromJson(Map<String, dynamic> j) => SuburbStats(
    name: j['name'] as String? ?? '',
    residentialCount: j['residentialCount'] as int? ?? 0,
    medianLandM2: _d(j['medianLandM2']) ?? 0,
    medianBuildingM2: _d(j['medianBuildingM2']) ?? 0,
    gv2022: _d(j['gv2022']) ?? 0,
    gv2025: _d(j['gv2025']) ?? 0,
    growthPercent: _d(j['growthPercent']) ?? 0,
    annualGrowthPercent: _d(j['annualGrowthPercent']) ?? 0,
  );
}

/// How the City's raw sales list was narrowed to the comparables used.
class ComparableSummary {
  final int raw;
  final int included;
  final int excludedZeroPrice;
  final int excludedImplausible;
  final int excludedTooOld;
  final int excludedDissimilar;
  final double? medianPricePerDwellingM2;
  final double? medianPricePerErfM2;

  /// The radius the comparables were taken from; null = the whole area.
  final int? radiusM;
  final int excludedMultiProperty;
  final int excludedNoBuilding;
  final int excludedTooFar;

  const ComparableSummary({
    required this.raw,
    required this.included,
    required this.excludedZeroPrice,
    required this.excludedImplausible,
    required this.excludedTooOld,
    required this.excludedDissimilar,
    this.medianPricePerDwellingM2,
    this.medianPricePerErfM2,
    this.radiusM,
    this.excludedMultiProperty = 0,
    this.excludedNoBuilding = 0,
    this.excludedTooFar = 0,
  });

  factory ComparableSummary.fromJson(Map<String, dynamic> j) =>
      ComparableSummary(
        raw: j['raw'] as int? ?? 0,
        included: j['included'] as int? ?? 0,
        excludedZeroPrice: j['excludedZeroPrice'] as int? ?? 0,
        excludedImplausible: j['excludedImplausible'] as int? ?? 0,
        excludedTooOld: j['excludedTooOld'] as int? ?? 0,
        excludedDissimilar: j['excludedDissimilar'] as int? ?? 0,
        medianPricePerDwellingM2: _d(j['medianPricePerDwellingM2']),
        medianPricePerErfM2: _d(j['medianPricePerErfM2']),
        radiusM: j['radiusM'] as int?,
        excludedMultiProperty: j['excludedMultiProperty'] as int? ?? 0,
        excludedNoBuilding: j['excludedNoBuilding'] as int? ?? 0,
        excludedTooFar: j['excludedTooFar'] as int? ?? 0,
      );
}

/// An indicative range: never a single number.
class ValueRange {
  final double? low;
  final double? mid;
  final double? high;

  const ValueRange({this.low, this.mid, this.high});

  factory ValueRange.fromJson(Map<String, dynamic> j) =>
      ValueRange(low: _d(j['low']), mid: _d(j['mid']), high: _d(j['high']));
}

/// A registered sale of the subject property itself.
class SaleRecord {
  final DateTime date;
  final double priceZar;
  const SaleRecord(this.date, this.priceZar);

  static SaleRecord? fromJson(Map<String, dynamic>? j) {
    final date = DateTime.tryParse(j?['saleDate'] as String? ?? '');
    final price = _d(j?['priceZar']);
    return date == null || price == null ? null : SaleRecord(date, price);
  }
}

class YearlySales {
  final int year;
  final int sales;
  final double medianPriceZar;
  const YearlySales(this.year, this.sales, this.medianPriceZar);
}

class PriceBand {
  final double fromZar;
  final double toZar;
  final int sales;
  final double percent;
  const PriceBand(this.fromZar, this.toZar, this.sales, this.percent);
}

/// Every market sale in the area the comparables came from, by year and by
/// price band (for the report's charts).
class AreaMarket {
  final int? radiusM;
  final int sales;
  final double? medianPriceZar;
  final List<YearlySales> byYear;
  final List<PriceBand> priceBands;

  const AreaMarket({
    this.radiusM,
    required this.sales,
    this.medianPriceZar,
    this.byYear = const [],
    this.priceBands = const [],
  });

  static AreaMarket? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : AreaMarket(
          radiusM: j['radiusM'] as int?,
          sales: j['sales'] as int? ?? 0,
          medianPriceZar: _d(j['medianPriceZar']),
          byYear: [
            for (final y in (j['byYear'] as List? ?? const []))
              YearlySales(
                y['year'] as int,
                y['sales'] as int? ?? 0,
                _d(y['medianPriceZar']) ?? 0,
              ),
          ],
          priceBands: [
            for (final b in (j['priceBands'] as List? ?? const []))
              PriceBand(
                _d(b['fromZar']) ?? 0,
                _d(b['toZar']) ?? 0,
                b['sales'] as int? ?? 0,
                _d(b['percent']) ?? 0,
              ),
          ],
        );
}

/// Where a figure in the report came from.
class Provenance {
  final String field;
  final String source;
  final DateTime fetchedAt;

  const Provenance({
    required this.field,
    required this.source,
    required this.fetchedAt,
  });

  factory Provenance.fromJson(Map<String, dynamic> j) => Provenance(
    field: j['field'] as String,
    source: j['source'] as String,
    fetchedAt: DateTime.parse(j['fetchedAtUtc'] as String),
  );
}

class PropertyReport {
  final String municipality;
  final String erf;
  final String? valuationRef;
  final String address;
  final String suburb;
  final String township;
  final double? lat;
  final double? lng;

  final double? extentM2;
  final double? extentM2Geodesic;
  final String? zoningCode;
  final String? zoningDescription;
  final String? ward;
  final String? subCouncil;
  final String? legalStatus;

  final double? dwellingExtentM2;
  final double? totalRoofM2;
  final List<Building> buildings;
  final List<ApprovedWork> approvedWork;

  final double? municipalValueZar;
  final DateTime? municipalValueAsAt;
  final String? ratingCategory;
  final String? rollVersion;

  final SuburbStats? suburbStats;
  final List<ComparableSale> comparables;
  final ComparableSummary? comparableSummary;
  final ValueRange? indicativeValue;

  /// Set when [indicativeValue] was carried to the floor area captured on the
  /// listing (not the City's dwelling extent); see [forListingFloorArea].
  final double? sizedFromListingM2;

  final List<ImageryRef> imagery;
  final String sitePlanUrl;

  /// The neighbourhood map (SVG, our drawing from City open data); add
  /// `&mode=block` for the close-up. Null where it is not drawn.
  final String? areaMapUrl;
  final List<Provenance> provenance;
  final DateTime generatedAt;

  /// Who published the data, e.g. "City of Johannesburg open data".
  final String dataSource;

  /// How the comparables were chosen, as a sentence to print.
  final String? comparablesMethod;

  /// What this area's data cannot provide (e.g. no building sizes in
  /// Johannesburg, only erf details elsewhere). Null for full coverage.
  final String? coverageNote;

  final DateTime? rollEffectiveFrom;

  /// The subject's own last registered sale, when the source publishes it.
  final SaleRecord? lastSale;

  /// The latest sales in the subject's own street.
  final List<ComparableSale> streetSales;

  final AreaMarket? areaMarket;

  /// Sales agents reported in the suburb. Null when the API could not read
  /// them; empty when none were reported.
  final AgentSalesSummary? agentSales;

  const PropertyReport({
    required this.municipality,
    required this.erf,
    required this.address,
    required this.suburb,
    required this.township,
    required this.buildings,
    required this.approvedWork,
    required this.comparables,
    required this.imagery,
    required this.sitePlanUrl,
    this.areaMapUrl,
    required this.provenance,
    required this.generatedAt,
    this.dataSource = 'City of Cape Town open data',
    this.comparablesMethod,
    this.coverageNote,
    this.rollEffectiveFrom,
    this.lastSale,
    this.streetSales = const [],
    this.areaMarket,
    this.agentSales,
    this.valuationRef,
    this.lat,
    this.lng,
    this.extentM2,
    this.extentM2Geodesic,
    this.zoningCode,
    this.zoningDescription,
    this.ward,
    this.subCouncil,
    this.legalStatus,
    this.dwellingExtentM2,
    this.totalRoofM2,
    this.municipalValueZar,
    this.municipalValueAsAt,
    this.ratingCategory,
    this.rollVersion,
    this.suburbStats,
    this.comparableSummary,
    this.indicativeValue,
    this.sizedFromListingM2,
  });

  factory PropertyReport.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final e in (j[key] as List? ?? const []))
        parse(e as Map<String, dynamic>),
    ];
    final asAt = j['municipalValueAsAt'] as String?;
    final effective = j['rollEffectiveFrom'] as String?;
    return PropertyReport(
      municipality: j['municipality'] as String? ?? 'coct',
      erf: j['erf'] as String,
      valuationRef: j['valuationRef'] as String?,
      address: j['address'] as String? ?? '',
      suburb: j['suburb'] as String? ?? '',
      township: j['township'] as String? ?? '',
      lat: _d(j['lat']),
      lng: _d(j['lng']),
      extentM2: _d(j['extentM2']),
      extentM2Geodesic: _d(j['extentM2Geodesic']),
      zoningCode: j['zoningCode'] as String?,
      zoningDescription: j['zoningDescription'] as String?,
      ward: j['ward'] as String?,
      subCouncil: j['subCouncil'] as String?,
      legalStatus: j['legalStatus'] as String?,
      dwellingExtentM2: _d(j['dwellingExtentM2']),
      totalRoofM2: _d(j['totalRoofM2']),
      buildings: list('buildings', Building.fromJson),
      approvedWork: list('approvedWork', ApprovedWork.fromJson),
      municipalValueZar: _d(j['municipalValueZar']),
      municipalValueAsAt: asAt == null ? null : DateTime.tryParse(asAt),
      ratingCategory: j['ratingCategory'] as String?,
      rollVersion: j['rollVersion'] as String?,
      suburbStats: j['suburbs'] == null
          ? null
          : SuburbStats.fromJson(j['suburbs'] as Map<String, dynamic>),
      comparables: list('comparables', ComparableSale.fromJson),
      comparableSummary: j['comparableSummary'] == null
          ? null
          : ComparableSummary.fromJson(
              j['comparableSummary'] as Map<String, dynamic>,
            ),
      indicativeValue: j['indicativeValue'] == null
          ? null
          : ValueRange.fromJson(j['indicativeValue'] as Map<String, dynamic>),
      imagery: list('imagery', ImageryRef.fromJson),
      sitePlanUrl: j['sitePlanUrl'] as String? ?? '',
      areaMapUrl: j['areaMapUrl'] as String?,
      provenance: list('provenance', Provenance.fromJson),
      dataSource: j['dataSource'] as String? ?? 'City of Cape Town open data',
      comparablesMethod: j['comparablesMethod'] as String?,
      coverageNote: j['coverageNote'] as String?,
      rollEffectiveFrom: effective == null
          ? null
          : DateTime.tryParse(effective),
      generatedAt:
          DateTime.tryParse(j['generatedAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      lastSale: SaleRecord.fromJson(j['lastSale'] as Map<String, dynamic>?),
      streetSales: list('streetSales', ComparableSale.fromJson),
      areaMarket: AreaMarket.fromJson(j['areaMarket'] as Map<String, dynamic>?),
      agentSales: j['agentComparables'] == null
          ? null
          : AgentSalesSummary.fromJson(
              j['agentComparables'] as Map<String, dynamic>,
            ),
    );
  }

  /// The address in title case, e.g. "17 Pine Road, Claremont".
  String get displayAddress {
    final a = _title(address);
    final s = _title(suburb);
    if (s.isEmpty || !a.endsWith(s)) return a;
    return '${a.substring(0, a.length - s.length).trim()}, $s';
  }

  /// This report with the indicative range carried to [floorM2], the floor
  /// area the agent captured, when it differs from the City's dwelling extent
  /// by more than 5%: each included sale (indexed to today) scaled with the
  /// same size elasticity the API uses (0.6), then the median and the
  /// interpolated quartiles, rounded to R 10 000.
  PropertyReport forListingFloorArea(double? floorM2) {
    final city = dwellingExtentM2;
    if (floorM2 == null || floorM2 <= 0 || indicativeValue == null) return this;
    if (city != null && city > 0 && (floorM2 / city - 1).abs() <= 0.05) {
      return this;
    }
    final implied = [
      for (final c in includedComparables)
        if (c.dwellingExtentM2 > 0)
          (c.indexedPriceZar ?? c.salePriceZar) *
              math.pow(floorM2 / c.dwellingExtentM2, sizeElasticity),
    ]..sort();
    if (implied.isEmpty) return this;
    double at(double q) {
      final pos = q * (implied.length - 1);
      final lo = pos.floor();
      final hi = math.min(lo + 1, implied.length - 1);
      return implied[lo] + (implied[hi] - implied[lo]) * (pos - lo);
    }

    double r(double v) => (v / 10000).round() * 10000.0;
    return PropertyReport(
      municipality: municipality,
      erf: erf,
      address: address,
      suburb: suburb,
      township: township,
      buildings: buildings,
      approvedWork: approvedWork,
      comparables: comparables,
      imagery: imagery,
      sitePlanUrl: sitePlanUrl,
      areaMapUrl: areaMapUrl,
      provenance: provenance,
      generatedAt: generatedAt,
      dataSource: dataSource,
      comparablesMethod: comparablesMethod,
      coverageNote: coverageNote,
      rollEffectiveFrom: rollEffectiveFrom,
      lastSale: lastSale,
      streetSales: streetSales,
      areaMarket: areaMarket,
      agentSales: agentSales,
      valuationRef: valuationRef,
      lat: lat,
      lng: lng,
      extentM2: extentM2,
      extentM2Geodesic: extentM2Geodesic,
      zoningCode: zoningCode,
      zoningDescription: zoningDescription,
      ward: ward,
      subCouncil: subCouncil,
      legalStatus: legalStatus,
      dwellingExtentM2: dwellingExtentM2,
      totalRoofM2: totalRoofM2,
      municipalValueZar: municipalValueZar,
      municipalValueAsAt: municipalValueAsAt,
      ratingCategory: ratingCategory,
      rollVersion: rollVersion,
      suburbStats: suburbStats,
      comparableSummary: comparableSummary,
      indicativeValue: ValueRange(
        low: r(at(0.25)),
        mid: r(at(0.5)),
        high: r(at(0.75)),
      ),
      sizedFromListingM2: floorM2,
    );
  }

  /// How much of a price difference a size difference makes: a home twice
  /// the size sells for about 2^0.6 = 1.5 times as much (as in the API).
  static const sizeElasticity = 0.6;

  /// The range to show: from municipal sales when there is one, otherwise
  /// from agent-reported sales (see [rangeFromAgentSales]).
  ValueRange? get bestRange => indicativeValue ?? agentSales?.indicativeValue;

  /// True when [bestRange] comes from agent-reported sales, which the report
  /// must say, since they are not registered transfers.
  bool get rangeFromAgentSales =>
      indicativeValue == null && agentSales?.indicativeValue != null;

  List<ComparableSale> get includedComparables =>
      comparables.where((c) => c.included).toList();

  /// Imagery that may go into the PDF. Street View is excluded by the server.
  List<ImageryRef> get printableImagery =>
      imagery.where((i) => i.allowedInPrint).toList();

  /// Screen-only imagery. Shown in the app; never in the export.
  List<ImageryRef> get screenOnlyImagery =>
      imagery.where((i) => !i.allowedInPrint).toList();
}

/// "CLAREMONT" -> "Claremont", "17 PINE ROAD CLAREMONT" -> "17 Pine Road Claremont".
String _title(String s) => s
    .toLowerCase()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// Public for the widgets and the PDF.
String titleCase(String s) => _title(s);

/// Whole numbers grouped the South African way: 7100000 -> "7 100 000".
/// The spaces are non-breaking, so a figure never wraps across two lines.
String groupDigits(num v) {
  final digits = v.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return v < 0 ? '-$grouped' : grouped;
}

/// Rand, whole: "R 7 100 000" (non-breaking after the R too).
String rand(num v) => 'R ${groupDigits(v)}';
