class ApiEndpoints {
  ApiEndpoints._();

  // Lookups
  static const String propertyTypes = '/api/property-types';
  static const String roomTypes = '/api/room-types';
  static const String features = '/api/features';
  static const String conditionCategories = '/api/condition-categories';
  static const String parkingTypes = '/api/parking-types';
  static const String facing = '/api/facing';
  static const String zoning = '/api/zoning';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // Agent profile
  static const String agentMe = '/api/agents/me';

  // Listings
  static const String listings = '/api/listings';

  static String listing(int id) => '/api/listings/$id';
  static String listingSubmit(int id) => '/api/listings/$id/submit';
  static String listingHouseScore(int id) => '/api/listings/$id/house-score';
  static String listingAddress(int id) => '/api/listings/$id/address';

  static String listingBuildingInfo(int id) =>
      '/api/listings/$id/building-info';
  static String listingValuation(int id) => '/api/listings/$id/valuation';

  static String listingRunningCosts(int id) =>
      '/api/listings/$id/running-costs';
  static String listingRooms(int id) => '/api/listings/$id/rooms';
  static String listingRoom(int listingId, int roomId) =>
      '/api/listings/$listingId/rooms/$roomId';
  static String listingRoomCondition(int listingId, int roomId) =>
      '/api/listings/$listingId/rooms/$roomId/condition';
  static String listingRoomFeatures(int listingId, int roomId) =>
      '/api/listings/$listingId/rooms/$roomId/features';
  static String listingRoomFeature(int listingId, int roomId, int featureId) =>
      '/api/listings/$listingId/rooms/$roomId/features/$featureId';
  static String listingRoomCustomFeatures(int listingId, int roomId) =>
      '/api/listings/$listingId/rooms/$roomId/custom-features';
  static String listingRoomCustomFeature(
    int listingId,
    int roomId,
    int customFeatureId,
  ) =>
      '/api/listings/$listingId/rooms/$roomId/custom-features/$customFeatureId';

  static String listingRoomPhotos(int listingId, int roomId) =>
      '/api/listings/$listingId/rooms/$roomId/photos';

  static String listingRoomPhotoById(int listingId, int roomId, int photoId) =>
      '/api/listings/$listingId/rooms/$roomId/photos/$photoId';


  static String listingPhotos(int id) => '/api/listings/$id/photos';

  static String listingPhoto(int listingId, int photoId) =>
      '/api/listings/$listingId/photos/$photoId';

  static String listingPhotoPrimary(int listingId, int photoId) =>
      '/api/listings/$listingId/photos/$photoId/primary';
  static String listingDocuments(int id) => '/api/listings/$id/documents';

  static String listingDocument(int listingId, int documentId) =>
      '/api/listings/$listingId/documents/$documentId';
  static String listingParking(int id) => '/api/listings/$id/parking';
  static String listingSingleParking(int listingId, int parkingId) =>
      '/api/listings/$listingId/parking/$parkingId';

  static String listingOutdoorFeatures(int id) =>
      '/api/listings/$id/outdoor-features';
  static String listingContacts(int id) => '/api/listings/$id/contacts';
  static String listingSingleContact(int listingId, int contactId) =>
      '/api/listings/$listingId/contacts/$contactId';
}
