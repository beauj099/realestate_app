// Sales agents report themselves (`/api/comparables`) and the agency's own
// listings in a suburb. Agent-reported sales are shared with every agent
// working the suburb; who captured one is never sent, only whether it was you.

import 'property_report.dart' show ValueRange;

double? _d(Object? v) => (v as num?)?.toDouble();

/// How the agent knows about a sale. Each counts for a different weight on the
/// server. [deedsVerified] is only ever set by a match with the municipal
/// sales record, so it is not offered when capturing.
enum EvidenceLevel {
  ownTransaction('OwnTransaction', 'I handled this sale', 'Counts in full'),
  signedOffer(
    'SignedOffer',
    'I have seen the signed offer',
    'Counts almost in full',
  ),
  colleagueConfirmed(
    'ColleagueConfirmed',
    'The selling agent told me',
    'Counts about half',
  ),
  hearsay(
    'Hearsay',
    'I heard it sold for about this',
    'Counts about a third — still useful',
  ),
  deedsVerified('DeedsVerified', 'Matches the municipal sales record', '');

  const EvidenceLevel(this.wire, this.label, this.weightHint);

  final String wire;
  final String label;
  final String weightHint;

  static const capturable = [
    ownTransaction,
    signedOffer,
    colleagueConfirmed,
    hearsay,
  ];

  static EvidenceLevel fromWire(String? s) =>
      values.firstWhere((e) => e.wire == s, orElse: () => hearsay);
}

enum SaleCondition {
  poor('Poor', 'Needs work'),
  fair('Fair', 'Fair'),
  good('Good', 'Good'),
  veryGood('VeryGood', 'Very good'),
  renovated('Renovated', 'Renovated');

  const SaleCondition(this.wire, this.label);

  final String wire;
  final String label;

  static SaleCondition? fromWire(String? s) =>
      values.where((c) => c.wire == s).firstOrNull;
}

/// A sale an agent reported.
class AgentSale {
  final String id;
  final String address;
  final String suburb;
  final String? erf;
  final double? erfM2;
  final double? floorM2;
  final int? bedrooms;
  final SaleCondition? condition;
  final DateTime saleDate;
  final double salePriceZar;
  final double? pricePerFloorM2;
  final EvidenceLevel evidence;

  /// The server's plain description, e.g. "Signed offer seen".
  final String evidenceText;

  /// Unverified, Verified (matches the municipal record) or Disputed (the
  /// municipal record shows a materially different price).
  final String verification;
  final int corroborationCount;
  final double weight;
  final bool isMine;

  const AgentSale({
    required this.id,
    required this.address,
    required this.suburb,
    required this.saleDate,
    required this.salePriceZar,
    required this.evidence,
    required this.evidenceText,
    required this.verification,
    required this.corroborationCount,
    required this.weight,
    required this.isMine,
    this.erf,
    this.erfM2,
    this.floorM2,
    this.bedrooms,
    this.condition,
    this.pricePerFloorM2,
  });

  factory AgentSale.fromJson(Map<String, dynamic> j) => AgentSale(
    id: j['id'] as String,
    address: j['address'] as String? ?? '',
    suburb: j['suburb'] as String? ?? '',
    erf: j['erf'] as String?,
    erfM2: _d(j['erfM2']),
    floorM2: _d(j['floorM2']),
    bedrooms: j['bedrooms'] as int?,
    condition: SaleCondition.fromWire(j['condition'] as String?),
    saleDate: DateTime.parse(j['saleDate'] as String),
    salePriceZar: _d(j['salePriceZar']) ?? 0,
    pricePerFloorM2: _d(j['pricePerFloorM2']),
    evidence: EvidenceLevel.fromWire(j['evidenceLevel'] as String?),
    evidenceText: j['evidence'] as String? ?? '',
    verification: j['verification'] as String? ?? 'Unverified',
    corroborationCount: j['corroborationCount'] as int? ?? 0,
    weight: _d(j['weight']) ?? 0,
    isMine: j['isMine'] as bool? ?? false,
  );

  bool get isVerified => verification == 'Verified';
  bool get isDisputed => verification == 'Disputed';
}

/// Agent-reported sales in a report's suburb and what may be said about them.
class AgentSalesSummary {
  final List<AgentSale> sales;

  /// A sentence to print as is: how many, how each is known, how they count.
  final String evidenceStatement;
  final double? weightedMedianPerFloorM2;
  final double? weightedMedianPerErfM2;

  /// A range from these sales alone, when there are at least three usable.
  final ValueRange? indicativeValue;

  /// "floor" or "erf": which size the range was applied to.
  final String? indicativeBasis;

  const AgentSalesSummary({
    required this.sales,
    required this.evidenceStatement,
    this.weightedMedianPerFloorM2,
    this.weightedMedianPerErfM2,
    this.indicativeValue,
    this.indicativeBasis,
  });

  factory AgentSalesSummary.fromJson(Map<String, dynamic> j) =>
      AgentSalesSummary(
        sales: [
          for (final e in (j['sales'] as List? ?? const []))
            AgentSale.fromJson(e as Map<String, dynamic>),
        ],
        evidenceStatement: j['evidenceStatement'] as String? ?? '',
        weightedMedianPerFloorM2: _d(j['weightedMedianPerFloorM2']),
        weightedMedianPerErfM2: _d(j['weightedMedianPerErfM2']),
        indicativeValue: j['indicativeValue'] == null
            ? null
            : ValueRange.fromJson(j['indicativeValue'] as Map<String, dynamic>),
        indicativeBasis: j['indicativeBasis'] as String?,
      );
}

/// A sale being logged. [municipality] and [suburb] are the report's own, so
/// the sale is shared with agents who open reports in the same suburb.
class NewAgentSale {
  final String municipality;
  final String suburb;
  final String address;
  final DateTime saleDate;
  final double salePriceZar;
  final EvidenceLevel evidence;
  final double? floorM2;
  final double? erfM2;
  final int? bedrooms;
  final SaleCondition? condition;
  final String? notes;

  const NewAgentSale({
    required this.municipality,
    required this.suburb,
    required this.address,
    required this.saleDate,
    required this.salePriceZar,
    required this.evidence,
    this.floorM2,
    this.erfM2,
    this.bedrooms,
    this.condition,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'municipality': municipality,
    'suburb': suburb,
    'address': address.trim(),
    'saleDate':
        '${saleDate.year.toString().padLeft(4, '0')}-'
        '${saleDate.month.toString().padLeft(2, '0')}-'
        '${saleDate.day.toString().padLeft(2, '0')}',
    'salePriceZar': salePriceZar,
    'evidenceLevel': evidence.wire,
    'floorM2': ?floorM2,
    'erfM2': ?erfM2,
    'bedrooms': ?bedrooms,
    'condition': ?condition?.wire,
    if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

/// One of the agency's own listings in the suburb. Never carries owners.
class MarketListing {
  final int listingId;
  final String address;
  final String? suburb;
  final double? agentValuationZar;
  final double? erfM2;
  final double? floorM2;
  final double? valuationPerFloorM2;
  final String status;
  final int daysListed;
  final bool isArchived;

  const MarketListing({
    required this.listingId,
    required this.address,
    required this.status,
    required this.daysListed,
    required this.isArchived,
    this.suburb,
    this.agentValuationZar,
    this.erfM2,
    this.floorM2,
    this.valuationPerFloorM2,
  });

  factory MarketListing.fromJson(Map<String, dynamic> j) => MarketListing(
    listingId: j['listingId'] as int,
    address: j['address'] as String? ?? '',
    suburb: j['suburb'] as String?,
    agentValuationZar: _d(j['agentValuationZar']),
    erfM2: _d(j['erfM2']),
    floorM2: _d(j['floorM2']),
    valuationPerFloorM2: _d(j['valuationPerFloorM2']),
    status: j['status'] as String? ?? '',
    daysListed: j['daysListed'] as int? ?? 0,
    isArchived: j['isArchived'] as bool? ?? false,
  );
}
