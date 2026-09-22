class PropertyRunningCosts {
  final String monthlyLevy;
  final String monthlyRates;
  final String electricity;
  final String water;
  final String sewage;
  final String refuse;

  const PropertyRunningCosts({
    this.monthlyLevy = '',
    this.monthlyRates = '',
    this.electricity = '',
    this.water = '',
    this.sewage = '',
    this.refuse = '',
  });

  PropertyRunningCosts copyWith({
    String? monthlyLevy,
    String? monthlyRates,
    String? electricity,
    String? water,
    String? sewage,
    String? refuse,
  }) {
    return PropertyRunningCosts(
      monthlyLevy: monthlyLevy ?? this.monthlyLevy,
      monthlyRates: monthlyRates ?? this.monthlyRates,
      electricity: electricity ?? this.electricity,
      water: water ?? this.water,
      sewage: sewage ?? this.sewage,
      refuse: refuse ?? this.refuse,
    );
  }
}
