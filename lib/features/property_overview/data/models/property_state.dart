import 'contact.dart';
import 'listing_parking.dart';
import 'listing_valuation.dart';
import 'property_running_costs.dart';
import 'room.dart';

/// Sentinel used by [PropertyState.copyWith] to distinguish an explicit `null`
/// argument (which should clear a nullable field) from "argument not provided"
/// (which should keep the current value).
const Object _unset = Object();

class PropertyState {
  final String? selectedRoomId;

  // Property Type
  final int propertyTypeId;

  // Address & Identification
  final String streetNumber;
  final String street;
  final String unitNumber;
  final String suburb;
  final String city;
  final String province;
  final String country;
  final String postalCode;
  final String estateName;
  final String erfNumber;
  final double? latitude;
  final double? longitude;

  // Step 3: Building Info
  final String erfSize;
  final String floorArea;
  final String constructionYear;
  final int? facingId;
  final int? zoningId;

  // Step 4: Property Features
  final List<Room> rooms;
  final List<ListingParking> parking;
  final List<String> outdoorFeatures;
  final List<String> outdoorHiddenFeatures;

  // Step 5: Expenses
  final ListingValuation listingValuation;
  final PropertyRunningCosts propertyRunningCosts;

  /// Exterior shots of the property, first entry being the hero image.
  ///
  /// Entries are server photo URLs once uploaded; freshly picked shots stay
  /// as local file paths until the upload completes (or is retried at
  /// submit). Persisted via the listing-level photo endpoints
  /// (`/api/listings/{id}/photos`).
  final List<String> exteriorPhotos;

  // Step 6: Owner Details
  final Contact primaryContact;
  final List<Contact> coContacts;

  // API metadata
  final int? listingId;

  // Listing metadata
  final String referenceNumber;
  final String? p24Ref;
  final String? errorMessage;

  PropertyState({
    this.selectedRoomId,
    this.propertyTypeId = 0,
    this.streetNumber = '',
    this.street = '',
    this.unitNumber = '',
    this.suburb = '',
    this.city = '',
    this.province = '',
    this.country = '',
    this.postalCode = '',
    this.estateName = '',
    this.erfNumber = '',
    this.latitude,
    this.longitude,
    this.erfSize = '',
    this.floorArea = '',
    this.constructionYear = '',
    this.facingId,
    this.zoningId,
    this.listingId,
    this.rooms = const [],
    this.parking = const [],
    this.outdoorFeatures = const [],
    this.outdoorHiddenFeatures = const [],
    this.exteriorPhotos = const [],
    this.listingValuation = const ListingValuation(),
    this.propertyRunningCosts = const PropertyRunningCosts(),
    this.primaryContact = const Contact(),
    this.coContacts = const [],
    this.referenceNumber = '',
    this.p24Ref,
    this.errorMessage,
  });

  PropertyState copyWith({
    Object? selectedRoomId = _unset,
    int? propertyTypeId,
    String? streetNumber,
    String? street,
    String? unitNumber,
    String? suburb,
    String? city,
    String? province,
    String? country,
    String? postalCode,
    String? estateName,
    String? erfNumber,
    Object? latitude = _unset,
    Object? longitude = _unset,
    String? erfSize,
    String? floorArea,
    String? constructionYear,
    Object? facingId = _unset,
    Object? zoningId = _unset,
    List<Room>? rooms,
    List<ListingParking>? parking,
    List<String>? outdoorFeatures,
    List<String>? outdoorHiddenFeatures,
    List<String>? exteriorPhotos,
    ListingValuation? listingValuation,
    PropertyRunningCosts? propertyRunningCosts,
    Contact? primaryContact,
    List<Contact>? coContacts,
    Object? listingId = _unset,
    String? referenceNumber,
    Object? p24Ref = _unset,
    Object? errorMessage = _unset,
  }) {
    return PropertyState(
      selectedRoomId: identical(selectedRoomId, _unset)
          ? this.selectedRoomId
          : selectedRoomId as String?,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      streetNumber: streetNumber ?? this.streetNumber,
      street: street ?? this.street,
      unitNumber: unitNumber ?? this.unitNumber,
      suburb: suburb ?? this.suburb,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      estateName: estateName ?? this.estateName,
      erfNumber: erfNumber ?? this.erfNumber,
      latitude: identical(latitude, _unset)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      erfSize: erfSize ?? this.erfSize,
      floorArea: floorArea ?? this.floorArea,
      constructionYear: constructionYear ?? this.constructionYear,
      facingId: identical(facingId, _unset) ? this.facingId : facingId as int?,
      zoningId: identical(zoningId, _unset) ? this.zoningId : zoningId as int?,
      listingId: identical(listingId, _unset)
          ? this.listingId
          : listingId as int?,
      rooms: rooms ?? this.rooms,
      parking: parking ?? this.parking,
      outdoorFeatures: outdoorFeatures ?? this.outdoorFeatures,
      outdoorHiddenFeatures:
          outdoorHiddenFeatures ?? this.outdoorHiddenFeatures,
      exteriorPhotos: exteriorPhotos ?? this.exteriorPhotos,
      listingValuation: listingValuation ?? this.listingValuation,
      propertyRunningCosts: propertyRunningCosts ?? this.propertyRunningCosts,
      primaryContact: primaryContact ?? this.primaryContact,
      coContacts: coContacts ?? this.coContacts,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      p24Ref: identical(p24Ref, _unset) ? this.p24Ref : p24Ref as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
