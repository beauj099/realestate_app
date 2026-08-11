import '../data/models/property_state.dart';

extension ListingValuationActions on PropertyState {
  PropertyState withValuation({
    String? ownersNetPrice,
    String? agentValuation,
    String? commissionPercent,
  }) {
    return copyWith(
      listingValuation: listingValuation.copyWith(
        ownersNetPrice: ownersNetPrice,
        agentValuation: agentValuation,
        commissionPercent: commissionPercent,
      ),
    );
  }

  PropertyState withRunningCosts({
    String? monthlyLevy,
    String? monthlyRates,
    String? electricity,
    String? water,
  }) {
    return copyWith(
      propertyRunningCosts: propertyRunningCosts.copyWith(
        monthlyLevy: monthlyLevy,
        monthlyRates: monthlyRates,
        electricity: electricity,
        water: water,
      ),
    );
  }
}
