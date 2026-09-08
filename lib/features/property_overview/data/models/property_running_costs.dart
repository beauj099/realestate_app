class PropertyRunningCosts {
  final String monthlyLevy;
  final String monthlyRates;
  final String electricity;
  final String water;
  final String municipalAccount;

  const PropertyRunningCosts({
    this.monthlyLevy = '',
    this.monthlyRates = '',
    this.electricity = '',
    this.water = '',
    this.municipalAccount = '',
  });

  PropertyRunningCosts copyWith({
    String? monthlyLevy,
    String? monthlyRates,
    String? electricity,
    String? water,
    String? municipalAccount,
  }) {
    return PropertyRunningCosts(
      monthlyLevy: monthlyLevy ?? this.monthlyLevy,
      monthlyRates: monthlyRates ?? this.monthlyRates,
      electricity: electricity ?? this.electricity,
      water: water ?? this.water,
      municipalAccount: municipalAccount ?? this.municipalAccount,
    );
  }
}
