class ListingValuation {
  final String ownersNetPrice;
  final String agentValuation;
  final String commissionPercent;

  /// When the owners bought and for how much, as they tell the agent. The
  /// City's sales record only reaches back a few years, so the report shows
  /// this when it has no sale of its own.
  final String lastPurchasePrice;
  final DateTime? lastPurchaseDate;

  const ListingValuation({
    this.ownersNetPrice = '',
    this.agentValuation = '',
    this.commissionPercent = '',
    this.lastPurchasePrice = '',
    this.lastPurchaseDate,
  });

  ListingValuation copyWith({
    String? ownersNetPrice,
    String? agentValuation,
    String? commissionPercent,
    String? lastPurchasePrice,
    DateTime? lastPurchaseDate,
    bool clearLastPurchaseDate = false,
  }) {
    return ListingValuation(
      ownersNetPrice: ownersNetPrice ?? this.ownersNetPrice,
      agentValuation: agentValuation ?? this.agentValuation,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      lastPurchaseDate: clearLastPurchaseDate
          ? null
          : lastPurchaseDate ?? this.lastPurchaseDate,
    );
  }
}
