/// The listing's money: what the owners want, the agent's range and price,
/// commission and the figures the report pack's calculators use, and when
/// and how the owners bought.
///
/// Every figure the report pack uses lives here (Price & Commission), so
/// changing one and making the pack again is all a new report needs. Empty
/// calculator figures mean "use Report settings".
class ListingValuation {
  final String ownersNetPrice;

  /// The single valuation figure older builds captured; kept as the middle
  /// of [valueLow]–[valueHigh] when those are set.
  final String agentValuation;

  /// Commission when it sells within [commissionEarlyMonths].
  final String commissionPercent;

  /// The agent's range and asking price, and why the range differs from the
  /// recorded sales (for the letter).
  final String valueLow;
  final String valueHigh;
  final String listingPrice;
  final String adjustmentReason;

  /// Commission when it takes longer, the months that count as early, and
  /// whether VAT is added. Null/empty: Report settings.
  final String commissionLatePercent;
  final String commissionEarlyMonths;
  final bool? commissionIncludesVat;

  /// The buyer's bond for the costs page. Empty: Report settings.
  final String interestRatePercent;
  final String bondTermYears;
  final String depositPercent;

  /// When the owners bought and for how much, and their bond. The City's
  /// sales record only reaches back a few years, so the report shows this
  /// when it has no sale of its own.
  final String lastPurchasePrice;
  final DateTime? lastPurchaseDate;
  final String bondInstitution;
  final String bondAmount;

  const ListingValuation({
    this.ownersNetPrice = '',
    this.agentValuation = '',
    this.commissionPercent = '',
    this.valueLow = '',
    this.valueHigh = '',
    this.listingPrice = '',
    this.adjustmentReason = '',
    this.commissionLatePercent = '',
    this.commissionEarlyMonths = '',
    this.commissionIncludesVat,
    this.interestRatePercent = '',
    this.bondTermYears = '',
    this.depositPercent = '',
    this.lastPurchasePrice = '',
    this.lastPurchaseDate,
    this.bondInstitution = '',
    this.bondAmount = '',
  });

  ListingValuation copyWith({
    String? ownersNetPrice,
    String? agentValuation,
    String? commissionPercent,
    String? valueLow,
    String? valueHigh,
    String? listingPrice,
    String? adjustmentReason,
    String? commissionLatePercent,
    String? commissionEarlyMonths,
    bool? commissionIncludesVat,
    String? interestRatePercent,
    String? bondTermYears,
    String? depositPercent,
    String? lastPurchasePrice,
    DateTime? lastPurchaseDate,
    bool clearLastPurchaseDate = false,
    String? bondInstitution,
    String? bondAmount,
  }) {
    return ListingValuation(
      ownersNetPrice: ownersNetPrice ?? this.ownersNetPrice,
      agentValuation: agentValuation ?? this.agentValuation,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      valueLow: valueLow ?? this.valueLow,
      valueHigh: valueHigh ?? this.valueHigh,
      listingPrice: listingPrice ?? this.listingPrice,
      adjustmentReason: adjustmentReason ?? this.adjustmentReason,
      commissionLatePercent:
          commissionLatePercent ?? this.commissionLatePercent,
      commissionEarlyMonths:
          commissionEarlyMonths ?? this.commissionEarlyMonths,
      commissionIncludesVat:
          commissionIncludesVat ?? this.commissionIncludesVat,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      bondTermYears: bondTermYears ?? this.bondTermYears,
      depositPercent: depositPercent ?? this.depositPercent,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      lastPurchaseDate: clearLastPurchaseDate
          ? null
          : lastPurchaseDate ?? this.lastPurchaseDate,
      bondInstitution: bondInstitution ?? this.bondInstitution,
      bondAmount: bondAmount ?? this.bondAmount,
    );
  }

  /// Everything, for "has anything changed" comparisons.
  List<Object?> get content => [
    ownersNetPrice.trim(),
    agentValuation.trim(),
    commissionPercent.trim(),
    valueLow.trim(),
    valueHigh.trim(),
    listingPrice.trim(),
    adjustmentReason.trim(),
    commissionLatePercent.trim(),
    commissionEarlyMonths.trim(),
    commissionIncludesVat,
    interestRatePercent.trim(),
    bondTermYears.trim(),
    depositPercent.trim(),
    lastPurchasePrice.trim(),
    lastPurchaseDate?.toIso8601String() ?? '',
    bondInstitution.trim(),
    bondAmount.trim(),
  ];

  /// The owners' purchase is known (any of it).
  bool get hasPurchase =>
      lastPurchaseDate != null ||
      lastPurchasePrice.trim().isNotEmpty ||
      bondInstitution.trim().isNotEmpty ||
      bondAmount.trim().isNotEmpty;
}

/// Banks that register most South African home loans, for the bond picker.
const bondInstitutions = [
  'Absa',
  'FNB',
  'Nedbank',
  'Standard Bank',
  'Capitec',
  'Investec',
  'SA Home Loans',
  'Other',
];
