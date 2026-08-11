class PropertyRunningCosts {
  final String monthlyLevy;
  final String monthlyRates;
  final String electricity;
  final String water;

  const PropertyRunningCosts({
    this.monthlyLevy = '',
    this.monthlyRates = '',
    this.electricity = '',
    this.water = '',
  });

  PropertyRunningCosts copyWith({
    String? monthlyLevy,
    String? monthlyRates,
    String? electricity,
    String? water,
  }) {
    return PropertyRunningCosts(
      monthlyLevy: monthlyLevy ?? this.monthlyLevy,
      monthlyRates: monthlyRates ?? this.monthlyRates,
      electricity: electricity ?? this.electricity,
      water: water ?? this.water,
    );
  }
}
