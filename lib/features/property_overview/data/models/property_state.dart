import 'dart:convert';

import 'contact.dart';
import 'listing_document.dart';
import 'listing_parking.dart';
import 'listing_valuation.dart';
import 'property_running_costs.dart';
import 'room.dart';
import 'room_score.dart';

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

  /// Bills and statements (water, electricity, municipal, levies) attached
  /// under Expenses. Picked documents stay local until the section is saved.
  final List<ListingDocument> documents;

  /// Server ids of uploaded documents removed since the last save; deleted
  /// from the API when Expenses is saved, so backing out restores them.
  final List<int> removedDocumentIds;

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

  /// House score saved on the listing, as a percentage. Either the app's
  /// suggestion ([houseScoreIsManual] false) or the agent's own figure.
  final double? savedHouseScore;

  /// True once the agent has set the house score themselves; the app then
  /// stops replacing it with its suggestion.
  final bool houseScoreIsManual;
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
    this.documents = const [],
    this.removedDocumentIds = const [],
    this.primaryContact = const Contact(),
    this.coContacts = const [],
    this.referenceNumber = '',
    this.p24Ref,
    this.savedHouseScore,
    this.houseScoreIsManual = false,
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
    List<ListingDocument>? documents,
    List<int>? removedDocumentIds,
    Contact? primaryContact,
    List<Contact>? coContacts,
    Object? listingId = _unset,
    String? referenceNumber,
    Object? p24Ref = _unset,
    Object? savedHouseScore = _unset,
    bool? houseScoreIsManual,
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
      documents: documents ?? this.documents,
      removedDocumentIds: removedDocumentIds ?? this.removedDocumentIds,
      primaryContact: primaryContact ?? this.primaryContact,
      coContacts: coContacts ?? this.coContacts,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      p24Ref: identical(p24Ref, _unset) ? this.p24Ref : p24Ref as String?,
      savedHouseScore: identical(savedHouseScore, _unset)
          ? this.savedHouseScore
          : savedHouseScore as double?,
      houseScoreIsManual: houseScoreIsManual ?? this.houseScoreIsManual,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  /// Whether [other] holds the same data, ignoring UI-only state (the room
  /// being edited, an error message, which owner-type tab is showing) and
  /// timestamps.
  ///
  /// Section screens use this to decide whether backing out loses anything:
  /// toggling between owner types, or typing then deleting a value, leaves
  /// the content unchanged and should not prompt.
  bool sameContentAs(PropertyState other) =>
      jsonEncode(_content()) == jsonEncode(other._content());

  List<Object?> _content() => [
    propertyTypeId,
    p24Ref,
    streetNumber.trim(),
    street.trim(),
    unitNumber.trim(),
    suburb.trim(),
    city.trim(),
    province.trim(),
    country.trim(),
    postalCode.trim(),
    estateName.trim(),
    erfNumber.trim(),
    latitude,
    longitude,
    erfSize.trim(),
    floorArea.trim(),
    constructionYear.trim(),
    facingId,
    zoningId,
    [
      for (final r in rooms)
        [
          r.id,
          r.name,
          r.roomTypeId,
          r.roomTypeOther,
          r.conditionRating,
          r.score,
          r.notes.trim(),
          [for (final p in r.photos) p.path],
          [for (final f in r.features) f.description],
        ],
    ],
    [
      for (final p in parking) [p.parkingTypeId, p.quantity],
    ],
    outdoorFeatures,
    exteriorPhotos,
    [
      listingValuation.ownersNetPrice.trim(),
      listingValuation.agentValuation.trim(),
      listingValuation.commissionPercent.trim(),
    ],
    [
      propertyRunningCosts.monthlyLevy.trim(),
      propertyRunningCosts.monthlyRates.trim(),
      propertyRunningCosts.electricity.trim(),
      propertyRunningCosts.water.trim(),
      propertyRunningCosts.sewage.trim(),
      propertyRunningCosts.refuse.trim(),
    ],
    [
      for (final d in documents) [d.id, d.localPath, d.category.name],
    ],
    removedDocumentIds,
    [
      for (final c in [primaryContact, ...coContacts]) _contactContent(c),
    ],
  ];

  static List<String> _contactContent(Contact c) => [
    c.fullName.trim(),
    c.idNumber.trim(),
    c.companyName.trim(),
    c.companyRegistrationNumber.trim(),
    c.mobilePhone.trim(),
    c.emailAddress.trim(),
    c.role.trim(),
  ];

  /// Whether the agent has captured anything worth keeping.
  ///
  /// The property type alone does not count: a listing that is only "a house"
  /// is indistinguishable from the next one on the home screen, so leaving it
  /// untouched discards it rather than cluttering the list.
  bool get hasMeaningfulContent {
    final emptyContact = _contactContent(const Contact()).join();
    return [
          streetNumber,
          street,
          unitNumber,
          suburb,
          city,
          estateName,
          erfNumber,
          erfSize,
          floorArea,
          constructionYear,
          p24Ref ?? '',
          listingValuation.ownersNetPrice,
          listingValuation.agentValuation,
          listingValuation.commissionPercent,
        ].any((v) => v.trim().isNotEmpty) ||
        latitude != null ||
        facingId != null ||
        zoningId != null ||
        rooms.isNotEmpty ||
        parking.isNotEmpty ||
        outdoorFeatures.isNotEmpty ||
        exteriorPhotos.isNotEmpty ||
        documents.isNotEmpty ||
        isExpensesComplete ||
        [
          primaryContact,
          ...coContacts,
        ].any((c) => _contactContent(c).join() != emptyContact);
  }

  // --- Section completeness -------------------------------------------------
  // "Complete" means every field the section's Save requires is filled in, so
  // the overview's ticks agree with what each screen validates.

  bool get isAddressComplete =>
      street.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      country.trim().isNotEmpty;

  bool get isBuildingInfoComplete =>
      erfSize.trim().isNotEmpty || floorArea.trim().isNotEmpty;

  /// A room is "rated" once it has a condition rating or a score — either
  /// shows the agent has assessed it rather than just listed it.
  static bool isRoomRated(Room room) =>
      room.conditionRating != null || room.score != null;

  int get ratedRoomCount => rooms.where(isRoomRated).length;

  /// Complete once there is at least one room and every room is rated.
  bool get isFeaturesComplete =>
      rooms.isNotEmpty && ratedRoomCount == rooms.length;

  bool get isExpensesComplete => [
    propertyRunningCosts.monthlyLevy,
    propertyRunningCosts.monthlyRates,
    propertyRunningCosts.electricity,
    propertyRunningCosts.water,
    propertyRunningCosts.sewage,
    propertyRunningCosts.refuse,
  ].any((v) => v.trim().isNotEmpty);

  bool get isOwnerComplete {
    final c = primaryContact;
    final base =
        c.fullName.trim().isNotEmpty &&
        c.emailAddress.trim().isNotEmpty &&
        c.mobilePhone.trim().isNotEmpty;
    if (c.ownerType == OwnerType.business) {
      return base && c.companyName.trim().isNotEmpty;
    }
    return base;
  }

  bool get isValuationComplete =>
      listingValuation.ownersNetPrice.trim().isNotEmpty;

  /// The app's suggested house score as a percentage: the room scores,
  /// weighted by how much each kind of room matters (see
  /// [RoomScore.weightFor]). Null until a room is scored.
  double? get suggestedHouseScore => RoomScore.suggestedHousePercent(rooms);

  /// The house score to show: the agent's own figure when they set one,
  /// otherwise the suggestion.
  double? get houseScore =>
      houseScoreIsManual ? savedHouseScore : suggestedHouseScore;

  int get scoredRoomCount => rooms.where((r) => r.score != null).length;
}
