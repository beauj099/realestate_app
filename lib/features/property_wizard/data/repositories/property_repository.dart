import '../models/contact.dart';
import '../models/listing_parking.dart';
import '../models/property_state.dart';
import '../models/room.dart';

abstract class IPropertyRepository {
  Future<List<Room>> getInitialRooms();
  Future<void> savePropertyDraft(PropertyState propertyState);

  Future<int> createListing(int propertyTypeId);
  Future<void> upsertAddress(int listingId, PropertyState state);
  Future<void> upsertBuildingInfo(int listingId, PropertyState state);
  Future<void> upsertValuation(int listingId, PropertyState state);
  Future<void> upsertRunningCosts(int listingId, PropertyState state);
  Future<void> upsertRooms(int listingId, List<Room> rooms);
  Future<void> upsertParking(int listingId, List<ListingParking> parking);

  Future<void> upsertContacts(
    int listingId,
    Contact primaryContact,
    List<Contact> coContacts,
  );
  Future<void> submitListing(int listingId);

  Future<void> uploadRoomPhoto(int listingId, int roomId, String filePath);
}
