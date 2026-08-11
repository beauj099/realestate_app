class ListingValuation {
  final String ownersNetPrice;
  final String agentValuation;
  final String commissionPercent;

  const ListingValuation({
    this.ownersNetPrice = '',
    this.agentValuation = '',
    this.commissionPercent = '',
  });

  ListingValuation copyWith({
    String? ownersNetPrice,
    String? agentValuation,
    String? commissionPercent,
  }) {
    return ListingValuation(
      ownersNetPrice: ownersNetPrice ?? this.ownersNetPrice,
      agentValuation: agentValuation ?? this.agentValuation,
      commissionPercent: commissionPercent ?? this.commissionPercent,
    );
  }
}
