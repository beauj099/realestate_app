class UpsertValuationRequest {
  final num? ownersNetPrice;
  final num? agentValuation;
  final num? commissionPercent;

  const UpsertValuationRequest({
    this.ownersNetPrice,
    this.agentValuation,
    this.commissionPercent,
  });

  Map<String, dynamic> toJson() => {
        if (ownersNetPrice != null) 'ownersNetPrice': ownersNetPrice,
        if (agentValuation != null) 'agentValuation': agentValuation,
        if (commissionPercent != null) 'commissionPercent': commissionPercent,
      };
}

class ValuationDto {
  final int id;
  final num? ownersNetPrice;
  final num? agentValuation;
  final num? commissionPercent;

  const ValuationDto({
    required this.id,
    this.ownersNetPrice,
    this.agentValuation,
    this.commissionPercent,
  });

  factory ValuationDto.fromJson(Map<String, dynamic> json) {
    return ValuationDto(
      id: json['id'] as int,
      ownersNetPrice: json['ownersNetPrice'] as num?,
      agentValuation: json['agentValuation'] as num?,
      commissionPercent: json['commissionPercent'] as num?,
    );
  }
}

class UpsertRunningCostsRequest {
  final num? monthlyLevy;
  final num? monthlyRates;
  final num? electricity;
  final num? water;

  const UpsertRunningCostsRequest({
    this.monthlyLevy,
    this.monthlyRates,
    this.electricity,
    this.water,
  });

  Map<String, dynamic> toJson() => {
        if (monthlyLevy != null) 'monthlyLevy': monthlyLevy,
        if (monthlyRates != null) 'monthlyRates': monthlyRates,
        if (electricity != null) 'electricity': electricity,
        if (water != null) 'water': water,
      };
}

class RunningCostsDto {
  final int id;
  final int listingId;
  final num? monthlyLevy;
  final num? monthlyRates;
  final num? electricity;
  final num? water;

  const RunningCostsDto({
    required this.id,
    required this.listingId,
    this.monthlyLevy,
    this.monthlyRates,
    this.electricity,
    this.water,
  });

  factory RunningCostsDto.fromJson(Map<String, dynamic> json) {
    return RunningCostsDto(
      id: json['id'] as int,
      listingId: json['listingId'] as int,
      monthlyLevy: json['monthlyLevy'] as num?,
      monthlyRates: json['monthlyRates'] as num?,
      electricity: json['electricity'] as num?,
      water: json['water'] as num?,
    );
  }
}
