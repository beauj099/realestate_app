/// Route paths shared between the router and screens.
abstract final class AppRoutes {
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String homePath = '/home';
  static const String settingsPath = '/settings';
  static const String profilePath = '/profile';

  static const String propertyPath = '/property/:id';

  /// Deprecated: property type is a dropdown on the property overview screen.
  /// The route is kept as a redirect so old deep links still resolve.
  static const String propertyTypePath = '/property/:id/property-type';
  static const String addressPath = '/property/:id/address';
  static const String buildingInfoPath = '/property/:id/building-info';
  static const String propertyFeaturesPath = '/property/:id/property-features';
  static const String roomDetailsPath = '/property/:id/room-details/:roomId';
  static const String expensesPath = '/property/:id/expenses';
  static const String valuationPath = '/property/:id/valuation';
  static const String ownerDetailsPath = '/property/:id/owner-details';

  // Deprecated: use ownerDetailsPath instead
  static const String contactsPath = '/property/:id/contacts';

  // Deprecated: use expensesPath instead
  static const String valuationCostsPath = '/property/:id/valuation-costs';

  static String property(int id) => '/property/$id';
  static String propertyType(int id) => '/property/$id/property-type';
  static String address(int id) => '/property/$id/address';
  static String buildingInfo(int id) => '/property/$id/building-info';
  static String propertyFeatures(int id) => '/property/$id/property-features';
  static String roomDetails(int id, String roomId) =>
      '/property/$id/room-details/$roomId';

  static String expenses(int id) => '/property/$id/expenses';

  static String valuation(int id) => '/property/$id/valuation';

  static String valuationCosts(int id) => expenses(id);

  static String ownerDetails(int id) => '/property/$id/owner-details';

  static String contacts(int id) => ownerDetails(id);
}
