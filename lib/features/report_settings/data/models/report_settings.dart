// An agent's own defaults for the valuation report pack, saved on their
// profile (`PUT /api/agents/me/report-settings`) so they follow the agent
// across devices. Every report can still change them for itself.

double _d(Object? v, double fallback) => (v as num?)?.toDouble() ?? fallback;

/// Defaults for the "Costs to seller and buyer" page.
class CalculatorDefaults {
  /// Commission when the property sells within [earlyMonths] of listing.
  final double commissionEarlyPercent;

  /// Commission when it takes longer.
  final double commissionLatePercent;
  final int earlyMonths;

  /// Whether VAT (15%) is added to the commission.
  final bool commissionIncludesVat;

  /// Home-loan interest rate for the buyer's repayment estimate.
  final double interestRatePercent;
  final int bondTermYears;

  /// Deposit the buyer puts down, as a share of the price.
  final double depositPercent;

  const CalculatorDefaults({
    this.commissionEarlyPercent = 5,
    this.commissionLatePercent = 6,
    this.earlyMonths = 2,
    this.commissionIncludesVat = false,
    this.interestRatePercent = 10.5,
    this.bondTermYears = 20,
    this.depositPercent = 0,
  });

  CalculatorDefaults copyWith({
    double? commissionEarlyPercent,
    double? commissionLatePercent,
    int? earlyMonths,
    bool? commissionIncludesVat,
    double? interestRatePercent,
    int? bondTermYears,
    double? depositPercent,
  }) => CalculatorDefaults(
    commissionEarlyPercent:
        commissionEarlyPercent ?? this.commissionEarlyPercent,
    commissionLatePercent: commissionLatePercent ?? this.commissionLatePercent,
    earlyMonths: earlyMonths ?? this.earlyMonths,
    commissionIncludesVat: commissionIncludesVat ?? this.commissionIncludesVat,
    interestRatePercent: interestRatePercent ?? this.interestRatePercent,
    bondTermYears: bondTermYears ?? this.bondTermYears,
    depositPercent: depositPercent ?? this.depositPercent,
  );

  factory CalculatorDefaults.fromJson(Map<String, dynamic>? j) {
    const d = CalculatorDefaults();
    if (j == null) return d;
    return CalculatorDefaults(
      commissionEarlyPercent: _d(
        j['commissionEarlyPercent'],
        d.commissionEarlyPercent,
      ),
      commissionLatePercent: _d(
        j['commissionLatePercent'],
        d.commissionLatePercent,
      ),
      earlyMonths: (j['earlyMonths'] as num?)?.toInt() ?? d.earlyMonths,
      commissionIncludesVat:
          j['commissionIncludesVat'] as bool? ?? d.commissionIncludesVat,
      interestRatePercent: _d(j['interestRatePercent'], d.interestRatePercent),
      bondTermYears: (j['bondTermYears'] as num?)?.toInt() ?? d.bondTermYears,
      depositPercent: _d(j['depositPercent'], d.depositPercent),
    );
  }

  Map<String, dynamic> toJson() => {
    'commissionEarlyPercent': commissionEarlyPercent,
    'commissionLatePercent': commissionLatePercent,
    'earlyMonths': earlyMonths,
    'commissionIncludesVat': commissionIncludesVat,
    'interestRatePercent': interestRatePercent,
    'bondTermYears': bondTermYears,
    'depositPercent': depositPercent,
  };
}

/// The kinds of room the house score weighs differently.
enum RoomWeightClass {
  kitchen('Kitchen', 3),
  mainBedroom('Main bedroom', 2.5),
  bathroom('Bathrooms & en-suites', 2),
  mainLiving('Lounge, living & family rooms', 2),
  bedroom('Other bedrooms', 1.5),
  otherLiving('Other living spaces', 1.5),
  utility('Scullery, laundry, pantry, toilet', 1),
  workAndLeisure('Study, office & entertainment', 1),
  additional('Additional rooms', 0.75),
  storage('Storeroom, workshop, loft, staff', 0.5);

  const RoomWeightClass(this.label, this.defaultWeight);

  final String label;
  final double defaultWeight;
}

/// How much each kind of room counts towards the suggested house score.
class RoomWeights {
  final Map<RoomWeightClass, double> _weights;

  const RoomWeights([this._weights = const {}]);

  static const defaults = RoomWeights();

  double of(RoomWeightClass c) => _weights[c] ?? c.defaultWeight;

  bool get isDefault =>
      RoomWeightClass.values.every((c) => of(c) == c.defaultWeight);

  RoomWeights withWeight(RoomWeightClass c, double weight) =>
      RoomWeights({..._weights, c: weight});

  factory RoomWeights.fromJson(Map<String, dynamic>? j) {
    if (j == null) return defaults;
    return RoomWeights({
      for (final c in RoomWeightClass.values)
        if (j[c.name] case final num v) c: v.toDouble(),
    });
  }

  Map<String, dynamic> toJson() => {
    for (final c in RoomWeightClass.values) c.name: of(c),
  };
}

class ReportSettings {
  final CalculatorDefaults calculator;
  final RoomWeights roomWeights;

  const ReportSettings({
    this.calculator = const CalculatorDefaults(),
    this.roomWeights = RoomWeights.defaults,
  });

  ReportSettings copyWith({
    CalculatorDefaults? calculator,
    RoomWeights? roomWeights,
  }) => ReportSettings(
    calculator: calculator ?? this.calculator,
    roomWeights: roomWeights ?? this.roomWeights,
  );

  factory ReportSettings.fromJson(Map<String, dynamic>? j) => ReportSettings(
    calculator: CalculatorDefaults.fromJson(
      j?['calculator'] as Map<String, dynamic>?,
    ),
    roomWeights: RoomWeights.fromJson(
      j?['roomWeights'] as Map<String, dynamic>?,
    ),
  );

  Map<String, dynamic> toJson() => {
    'calculator': calculator.toJson(),
    'roomWeights': roomWeights.toJson(),
  };
}
