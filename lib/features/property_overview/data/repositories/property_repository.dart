import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dto/listing_dtos.dart';
import '../models/contact.dart';
import '../models/enums/outdoor_extra.dart';
import '../models/listing_parking.dart';
import '../models/listing_valuation.dart';
import '../models/property_running_costs.dart';
import '../models/property_state.dart';
import '../models/room.dart';

class PropertyRepository {
  final ApiClient _client;

  PropertyRepository(this._client);

  List<Map<String, dynamic>>? _conditionCategoriesCache;
  Map<String, int>? _featureIdByNameCache;

  /// Parking-category outdoor display strings, normalized for comparison.
  /// Parking is managed via the dedicated `/parking` endpoint, so these
  /// legacy outdoor entries are excluded when loading a listing.
  static final Set<String> _parkingOutdoorNames = OutdoorExtraCategory
      .parking
      .displayStrings
      .map((s) => s.trim().toLowerCase())
      .toSet();

  Future<List<Room>> getInitialRooms() async => [];

  Future<List<ListingSummaryDto>> getAllListings({
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();

    final response = await _client.get(
      ApiEndpoints.listings,
      queryParameters: params.isNotEmpty ? params : null,
    );
    return (response.data as List).map((e) {
      final j = e as Map<String, dynamic>;
      return ListingSummaryDto(
        id: j['id'] as int,
        referenceNumber: j['referenceNumber'] as String,
        p24Ref: j['p24Ref'] as String?,
        propertyTypeId: j['propertyTypeId'] as int? ?? 0,
        listingValuationId: j['listingValuationId'] as int?,
        listDate: j['listDate'] != null
            ? DateTime.parse(j['listDate'] as String)
            : null,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
    }).toList();
  }

  /// Fetches just enough of a listing to label it on the home screen.
  ///
  /// `GET /api/listings` returns only the reference number and status, which
  /// tells an agent nothing about which house it is. This pulls the address and
  /// primary owner from the single-listing endpoint instead.
  ///
  /// That is one request per card. Acceptable at the handful of listings an
  /// agent owns, but the right fix is for the list endpoint to return these
  /// fields — see `docs/BACKEND_CHANGES.md`.
  Future<({String addressLine, String ownerName})> getListingCardInfo(
    int listingId,
  ) async {
    final response = await _client.get(ApiEndpoints.listing(listingId));
    final j = response.data as Map<String, dynamic>;

    final address = j['address'] as Map<String, dynamic>?;
    final streetNumber = (address?['streetNumber'] ?? '').toString().trim();
    final street = (address?['street'] ?? '').toString().trim();
    final suburb = (address?['suburb'] ?? '').toString().trim();
    final city = (address?['city'] ?? '').toString().trim();

    final streetLine = [streetNumber, street].where((p) => p.isNotEmpty).join(' ');
    final addressLine = [
      streetLine,
      suburb,
      city,
    ].where((p) => p.isNotEmpty).join(', ');

    final contacts = (j['contacts'] as List<dynamic>?) ?? [];
    final owners = contacts
        .map((c) => c as Map<String, dynamic>)
        .map(
          (c) => ((c['companyName'] ?? '').toString().trim().isNotEmpty
                  ? c['companyName']
                  : c['fullName'] ?? '')
              .toString()
              .trim(),
        )
        .where((n) => n.isNotEmpty)
        .toList();

    return (
      addressLine: addressLine,
      // Two names fit a card; more than that becomes "+n".
      ownerName: owners.isEmpty
          ? ''
          : owners.length <= 2
          ? owners.join(' & ')
          : '${owners.take(2).join(' & ')} +${owners.length - 2}',
    );
  }

  Future<({int id, String referenceNumber})> createListing(
    int? propertyTypeId, {
    String? p24Ref,
  }) async {
    final data = <String, dynamic>{};
    if (propertyTypeId != null) data['propertyTypeId'] = propertyTypeId;
    if (p24Ref != null && p24Ref.isNotEmpty) data['p24Ref'] = p24Ref;
    final response = await _client.post(ApiEndpoints.listings, data: data);
    final json = response.data as Map<String, dynamic>;
    return (
      id: json['id'] as int,
      referenceNumber: json['referenceNumber'] as String? ?? '',
    );
  }

  Future<PropertyState> loadListing(int listingId) async {
    final response = await _client.get(ApiEndpoints.listing(listingId));
    final j = response.data as Map<String, dynamic>;

    final address = j['address'] as Map<String, dynamic>?;
    final buildingInfo = j['buildingInfo'] as Map<String, dynamic>?;
    final valuation = j['valuation'] as Map<String, dynamic>?;
    final runningCosts = j['runningCosts'] as Map<String, dynamic>?;

    final roomsJson = (j['rooms'] as List<dynamic>?) ?? [];
    final parkingJson = (j['parking'] as List<dynamic>?) ?? [];
    final contactsJson = (j['contacts'] as List<dynamic>?) ?? [];
    final outdoorJson = (j['outdoorFeatures'] as List<dynamic>?) ?? [];

    final contacts = contactsJson
        .map((c) => c as Map<String, dynamic>)
        .map(
          (c) => Contact(
            id: c['id'].toString(),
            fullName: c['fullName'] as String? ?? '',
            idNumber: c['idNumber'] as String? ?? '',
            companyName: c['companyName'] as String? ?? '',
            companyRegistrationNumber:
                c['companyRegistrationNumber'] as String? ?? '',
            mobilePhone: c['mobilePhone'] as String? ?? '',
            emailAddress: c['emailAddress'] as String? ?? '',
            role: c['role'] as String? ?? '',
          ),
        )
        .toList();

    return PropertyState(
      listingId: j['id'] as int?,
      propertyTypeId: j['propertyTypeId'] as int? ?? 0,
      referenceNumber: j['referenceNumber'] as String? ?? '',
      p24Ref: j['p24Ref'] as String?,
      streetNumber: address?['streetNumber'] as String? ?? '',
      street: address?['street'] as String? ?? '',
      unitNumber: address?['unitNumber'] as String? ?? '',
      suburb: address?['suburb'] as String? ?? '',
      city: address?['city'] as String? ?? '',
      province: address?['province'] as String? ?? '',
      country: address?['country'] as String? ?? '',
      postalCode: address?['postalCode'] as String? ?? '',
      estateName: address?['estateName'] as String? ?? '',
      erfNumber: address?['erfNumber'] as String? ?? '',
      latitude: (address?['latitude'] as num?)?.toDouble(),
      longitude: (address?['longitude'] as num?)?.toDouble(),
      erfSize: buildingInfo?['erfSize']?.toString() ?? '',
      floorArea: buildingInfo?['floorArea']?.toString() ?? '',
      constructionYear: buildingInfo?['constructionYear']?.toString() ?? '',
      facingId: buildingInfo?['facingId'] as int?,
      zoningId: buildingInfo?['zoningId'] as int?,
      rooms: roomsJson.map((r) => r as Map<String, dynamic>).map((r) {
        final condition = r['condition'] as Map<String, dynamic>?;
        final features =
            (r['features'] as List<dynamic>?)
                ?.map(
                  (f) => RoomFeature(
                    description:
                        (f as Map<String, dynamic>)['description'] as String,
                    featureId: f['id'] as int,
                  ),
                )
                .toList() ??
            [];
        final customFeatures =
            (r['customFeatures'] as List<dynamic>?)
                ?.map(
                  (f) => RoomFeature(
                    description:
                        (f as Map<String, dynamic>)['description'] as String,
                    customId: f['id'] as int,
                  ),
                )
                .toList() ??
            [];
        return Room(
          id: (r['id'] as int).toString(),
          name: r['name'] as String? ?? '',
          roomTypeId: r['roomTypeId'] as int? ?? 1,
          roomTypeOther: r['roomTypeOther'] as String?,
          conditionRating: _parseConditionRating(condition?['conditionRating']),
          features: [...features, ...customFeatures],
          notes: condition?['notes'] as String? ?? '',
          photoUrl: r['photoUrl'] as String?,
          createdAt: r['createdAt'] != null
              ? DateTime.parse(r['createdAt'] as String)
              : null,
          updatedAt: r['updatedAt'] != null
              ? DateTime.parse(r['updatedAt'] as String)
              : null,
        );
      }).toList(),
      parking: parkingJson
          .map((p) => p as Map<String, dynamic>)
          .map(
            (p) => ListingParking(
              id: p['id'].toString(),
              parkingTypeId: p['parkingTypeId'] as int? ?? 1,
              quantity: p['quantity'] as int? ?? 1,
            ),
          )
          .toList(),
      outdoorFeatures: outdoorJson
          .map((f) => (f as Map<String, dynamic>)['description'] as String)
          .where((f) => !_parkingOutdoorNames.contains(f.trim().toLowerCase()))
          .toList(),
      listingValuation: ListingValuation(
        ownersNetPrice: valuation?['ownersNetPrice']?.toString() ?? '',
        agentValuation: valuation?['agentValuation']?.toString() ?? '',
        commissionPercent: valuation?['commissionPercent']?.toString() ?? '',
      ),
      propertyRunningCosts: PropertyRunningCosts(
        monthlyLevy: runningCosts?['monthlyLevy']?.toString() ?? '',
        monthlyRates: runningCosts?['monthlyRates']?.toString() ?? '',
        electricity: runningCosts?['electricity']?.toString() ?? '',
        water: runningCosts?['water']?.toString() ?? '',
        municipalAccount: runningCosts?['municipalAccount']?.toString() ?? '',
      ),
      primaryContact: contacts.isNotEmpty ? contacts.first : const Contact(),
      coContacts: contacts.length > 1 ? contacts.sublist(1) : [],
    );
  }

  Future<void> updatePropertyType(
    int listingId,
    int propertyTypeId, {
    String? p24Ref,
  }) async {
    final data = <String, dynamic>{'propertyTypeId': propertyTypeId};
    if (p24Ref != null && p24Ref.isNotEmpty) data['p24Ref'] = p24Ref;
    await _client.put(ApiEndpoints.listing(listingId), data: data);
  }

  Future<void> upsertAddress(int listingId, PropertyState state) async {
    final data = <String, dynamic>{};
    if (state.streetNumber.isNotEmpty) {
      data['streetNumber'] = state.streetNumber;
    }
    if (state.street.isNotEmpty) data['street'] = state.street;
    if (state.unitNumber.isNotEmpty) data['unitNumber'] = state.unitNumber;
    if (state.suburb.isNotEmpty) data['suburb'] = state.suburb;
    if (state.city.isNotEmpty) data['city'] = state.city;
    if (state.province.isNotEmpty) data['province'] = state.province;
    if (state.country.isNotEmpty) data['country'] = state.country;
    if (state.postalCode.isNotEmpty) data['postalCode'] = state.postalCode;
    if (state.estateName.isNotEmpty) data['estateName'] = state.estateName;
    if (state.erfNumber.isNotEmpty) data['erfNumber'] = state.erfNumber;
    if (state.latitude != null) data['latitude'] = state.latitude;
    if (state.longitude != null) data['longitude'] = state.longitude;
    await _client.put(ApiEndpoints.listingAddress(listingId), data: data);
  }

  Future<void> upsertBuildingInfo(int listingId, PropertyState state) async {
    final data = <String, dynamic>{};
    if (state.erfSize.isNotEmpty) {
      data['erfSize'] = num.tryParse(state.erfSize);
    }
    if (state.floorArea.isNotEmpty) {
      data['floorArea'] = num.tryParse(state.floorArea);
    }
    if (state.constructionYear.isNotEmpty) {
      data['constructionYear'] = int.tryParse(state.constructionYear);
    }
    if (state.facingId != null) data['facingId'] = state.facingId;
    if (state.zoningId != null) data['zoningId'] = state.zoningId;
    await _client.put(ApiEndpoints.listingBuildingInfo(listingId), data: data);
  }

  Future<void> upsertValuation(int listingId, PropertyState state) async {
    final data = <String, dynamic>{};
    if (state.listingValuation.ownersNetPrice.isNotEmpty) {
      data['ownersNetPrice'] = _parseDecimal(
        state.listingValuation.ownersNetPrice,
      );
    }
    if (state.listingValuation.agentValuation.isNotEmpty) {
      data['agentValuation'] = _parseDecimal(
        state.listingValuation.agentValuation,
      );
    }
    if (state.listingValuation.commissionPercent.isNotEmpty) {
      data['commissionPercent'] = _parseDecimal(
        state.listingValuation.commissionPercent,
      );
    }
    await _client.put(ApiEndpoints.listingValuation(listingId), data: data);
  }

  Future<void> upsertRunningCosts(int listingId, PropertyState state) async {
    final data = <String, dynamic>{};
    if (state.propertyRunningCosts.monthlyLevy.isNotEmpty) {
      data['monthlyLevy'] = _parseDecimal(
        state.propertyRunningCosts.monthlyLevy,
      );
    }
    if (state.propertyRunningCosts.monthlyRates.isNotEmpty) {
      data['monthlyRates'] = _parseDecimal(
        state.propertyRunningCosts.monthlyRates,
      );
    }
    if (state.propertyRunningCosts.electricity.isNotEmpty) {
      data['electricity'] = _parseDecimal(
        state.propertyRunningCosts.electricity,
      );
    }
    if (state.propertyRunningCosts.water.isNotEmpty) {
      data['water'] = _parseDecimal(state.propertyRunningCosts.water);
    }
    if (state.propertyRunningCosts.municipalAccount.isNotEmpty) {
      data['municipalAccount'] = _parseDecimal(
        state.propertyRunningCosts.municipalAccount,
      );
    }
    await _client.put(ApiEndpoints.listingRunningCosts(listingId), data: data);
  }

  Future<List<Room>> upsertRooms(int listingId, List<Room> rooms) async {
    final existingRoomsJson = await _getRoomsJson(listingId);
    final existingMap = {
      for (final r in existingRoomsJson) (r['id'] as int): r,
    };

    final desiredApiIds = rooms
        .map((r) => int.tryParse(r.id))
        .whereType<int>()
        .toSet();

    for (final apiId in existingMap.keys.where(
      (id) => !desiredApiIds.contains(id),
    )) {
      await _client.delete(ApiEndpoints.listingRoom(listingId, apiId));
    }

    final syncedRooms = <Room>[];

    for (final room in rooms) {
      final apiId = int.tryParse(room.id);
      if (apiId != null && existingMap.containsKey(apiId)) {
        syncedRooms.add(
          await _syncExistingRoom(listingId, apiId, room, existingMap[apiId]!),
        );
      } else {
        syncedRooms.add(await _createRoomWithDetails(listingId, room));
      }
    }

    return syncedRooms;
  }

  Future<Room> _createRoomWithDetails(int listingId, Room room) async {
    final createdJson = await _createRoom(listingId, room);
    final createdId = createdJson['id'] as int;
    var photoUrl = room.photoUrl;

    if (photoUrl != null && !photoUrl.startsWith('http')) {
      try {
        photoUrl = await _uploadRoomPhoto(listingId, createdId, photoUrl);
      } catch (e) {
        developer.log('Room photo upload failed: $e');
      }
    }

    if (room.conditionRating != null) {
      await _upsertRoomCondition(
        listingId,
        createdId,
        conditionRating: room.conditionRating,
        notes: room.notes.isNotEmpty ? room.notes : null,
      );
    }

    final partitioned = await _partitionFeatures(room.features);
    for (final featureId in partitioned.linkedIds) {
      await _linkRoomFeature(listingId, createdId, featureId);
    }
    for (final description in partitioned.customDescriptions) {
      await _addCustomFeature(listingId, createdId, description);
    }

    return room.copyWith(id: createdId.toString(), photoUrl: photoUrl);
  }

  Future<Room> _syncExistingRoom(
    int listingId,
    int apiId,
    Room room,
    Map<String, dynamic> existing,
  ) async {
    var photoUrl = room.photoUrl;

    await _updateRoom(listingId, apiId, room);

    final existingPhotoUrl = existing['photoUrl'] as String?;
    if (existingPhotoUrl != null && (photoUrl == null || photoUrl.isEmpty)) {
      await _client.delete(ApiEndpoints.listingRoomPhoto(listingId, apiId));
    } else if (photoUrl != null && !photoUrl.startsWith('http')) {
      try {
        photoUrl = await _uploadRoomPhoto(listingId, apiId, photoUrl);
      } catch (e) {
        developer.log('Room photo upload failed: $e');
      }
    }

    final existingCondition = existing['condition'] as Map<String, dynamic>?;
    if (room.conditionRating !=
            _parseConditionRating(existingCondition?['conditionRating']) ||
        room.notes != (existingCondition?['notes'] as String? ?? '')) {
      await _upsertRoomCondition(
        listingId,
        apiId,
        conditionRating: room.conditionRating,
        notes: room.notes.isNotEmpty ? room.notes : null,
      );
    }

    final existingFeatureIds =
        (existing['features'] as List<dynamic>?)
            ?.map((f) => (f as Map<String, dynamic>)['id'] as int)
            .toSet() ??
        <int>{};
    final existingCustomFeatures =
        (existing['customFeatures'] as List<dynamic>?)
            ?.map((f) => f as Map<String, dynamic>)
            .toList() ??
        <Map<String, dynamic>>[];
    final existingCustomById = {
      for (final f in existingCustomFeatures)
        (f['id'] as int): (f['description'] as String),
    };
    final existingCustomDescriptions = existingCustomById.values.toSet();

    final partitioned = await _partitionFeatures(room.features);
    final desiredFeatureIds = partitioned.linkedIds;
    final desiredCustomDescriptions = partitioned.customDescriptions;

    for (final fid in desiredFeatureIds.difference(existingFeatureIds)) {
      await _linkRoomFeature(listingId, apiId, fid);
    }
    for (final fid in existingFeatureIds.difference(desiredFeatureIds)) {
      await _unlinkRoomFeature(listingId, apiId, fid);
    }
    for (final description in desiredCustomDescriptions.difference(
      existingCustomDescriptions,
    )) {
      await _addCustomFeature(listingId, apiId, description);
    }
    for (final entry in existingCustomById.entries) {
      if (!desiredCustomDescriptions.contains(entry.value)) {
        await _deleteCustomFeature(listingId, apiId, entry.key);
      }
    }

    return room.copyWith(photoUrl: photoUrl);
  }

  Future<void> upsertParking(
    int listingId,
    List<ListingParking> parking,
  ) async {
    final existingParkingJson = await _getParkingJson(listingId);
    final desiredTypeIds = parking.map((p) => p.parkingTypeId).toSet();
    final existingTypeIds = existingParkingJson
        .map((p) => p['parkingTypeId'] as int)
        .toSet();

    for (final existing in existingParkingJson) {
      final typeId = existing['parkingTypeId'] as int;
      if (!desiredTypeIds.contains(typeId)) {
        await _client.delete(
          ApiEndpoints.listingSingleParking(listingId, existing['id'] as int),
        );
      }
    }

    for (final p in parking) {
      if (existingTypeIds.contains(p.parkingTypeId)) {
        final existing = existingParkingJson.firstWhere(
          (ep) => ep['parkingTypeId'] == p.parkingTypeId,
        );
        await _client.put(
          ApiEndpoints.listingSingleParking(listingId, existing['id'] as int),
          data: {'quantity': p.quantity},
        );
      } else {
        await _client.post(
          ApiEndpoints.listingParking(listingId),
          data: {'parkingTypeId': p.parkingTypeId, 'quantity': p.quantity},
        );
      }
    }
  }

  Future<List<Contact>> upsertContacts(
    int listingId,
    Contact primaryContact,
    List<Contact> coContacts,
  ) async {
    final allContacts = [
      if (primaryContact.fullName.isNotEmpty) primaryContact,
      ...coContacts.where(_contactHasData),
    ];
    final existingJson = await _getContactsJson(listingId);
    final existingById = {for (final c in existingJson) (c['id'] as int): c};

    final desiredApiIds = allContacts
        .map((c) => int.tryParse(c.id))
        .whereType<int>()
        .toSet();

    for (final cid in existingById.keys.where(
      (id) => !desiredApiIds.contains(id),
    )) {
      await _client.delete(ApiEndpoints.listingSingleContact(listingId, cid));
    }

    final syncedContacts = <Contact>[];

    for (final contact in allContacts) {
      final data = <String, dynamic>{};
      if (contact.fullName.isNotEmpty) data['fullName'] = contact.fullName;
      if (contact.idNumber.isNotEmpty) data['idNumber'] = contact.idNumber;
      if (contact.companyName.isNotEmpty) {
        data['companyName'] = contact.companyName;
      }
      if (contact.companyRegistrationNumber.isNotEmpty) {
        data['companyRegistrationNumber'] = contact.companyRegistrationNumber;
      }
      if (contact.mobilePhone.isNotEmpty) {
        data['mobilePhone'] = contact.mobilePhone;
      }
      if (contact.emailAddress.isNotEmpty) {
        data['emailAddress'] = contact.emailAddress;
      }
      if (contact.role.isNotEmpty) data['role'] = contact.role;

      final apiId = int.tryParse(contact.id);
      if (apiId != null && existingById.containsKey(apiId)) {
        await _client.put(
          ApiEndpoints.listingSingleContact(listingId, apiId),
          data: data,
        );
        syncedContacts.add(contact);
      } else {
        final response = await _client.post(
          ApiEndpoints.listingContacts(listingId),
          data: data,
        );
        final created = response.data as Map<String, dynamic>;
        syncedContacts.add(contact.copyWith(id: created['id'].toString()));
      }
    }

    return syncedContacts;
  }

  Future<void> upsertOutdoorFeatures(
    int listingId,
    List<String> outdoorFeatures,
  ) async {
    await _client.put(
      ApiEndpoints.listingOutdoorFeatures(listingId),
      data: {'descriptions': outdoorFeatures},
    );
  }

  Future<void> submitListing(int listingId) async {
    await _client.put(ApiEndpoints.listingSubmit(listingId));
    developer.log('Listing submitted: ID=$listingId');
  }

  Future<void> deleteListing(int listingId) async {
    await _client.delete(ApiEndpoints.listing(listingId));
    developer.log('Listing deleted: ID=$listingId');
  }

  Future<String?> uploadRoomPhoto(int listingId, int roomId, String filePath) {
    return _uploadRoomPhoto(listingId, roomId, filePath);
  }

  Future<List<Map<String, dynamic>>> _getRoomsJson(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingRooms(listingId));
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _createRoom(int listingId, Room room) async {
    final data = <String, dynamic>{
      'name': room.name,
      'roomTypeId': room.roomTypeId,
    };
    if (room.roomTypeOther != null) data['roomTypeOther'] = room.roomTypeOther;
    if (room.photoUrl != null && room.photoUrl!.startsWith('http')) {
      data['photoUrl'] = room.photoUrl;
    }
    final response = await _client.post(
      ApiEndpoints.listingRooms(listingId),
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> _updateRoom(int listingId, int roomId, Room room) async {
    final data = <String, dynamic>{};
    if (room.name.isNotEmpty) data['name'] = room.name;
    data['roomTypeId'] = room.roomTypeId;
    if (room.roomTypeOther != null) data['roomTypeOther'] = room.roomTypeOther;
    if (room.photoUrl != null && room.photoUrl!.startsWith('http')) {
      data['photoUrl'] = room.photoUrl;
    }
    await _client.put(ApiEndpoints.listingRoom(listingId, roomId), data: data);
  }

  Future<void> _upsertRoomCondition(
    int listingId,
    int roomId, {
    int? conditionRating,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'conditionCategoryId': await _resolveConditionCategoryId(),
    };
    if (conditionRating != null) data['conditionRating'] = conditionRating;
    if (notes != null) data['notes'] = notes;
    await _client.put(
      ApiEndpoints.listingRoomCondition(listingId, roomId),
      data: data,
    );
  }

  Future<void> _linkRoomFeature(
    int listingId,
    int roomId,
    int featureId,
  ) async {
    await _client.post(
      ApiEndpoints.listingRoomFeatures(listingId, roomId),
      data: {'featureId': featureId},
    );
  }

  Future<void> _unlinkRoomFeature(
    int listingId,
    int roomId,
    int featureId,
  ) async {
    await _client.delete(
      ApiEndpoints.listingRoomFeature(listingId, roomId, featureId),
    );
  }

  Future<void> _addCustomFeature(
    int listingId,
    int roomId,
    String description,
  ) async {
    await _client.post(
      ApiEndpoints.listingRoomCustomFeatures(listingId, roomId),
      data: {'description': description},
    );
  }

  Future<void> _deleteCustomFeature(
    int listingId,
    int roomId,
    int customFeatureId,
  ) async {
    await _client.delete(
      ApiEndpoints.listingRoomCustomFeature(listingId, roomId, customFeatureId),
    );
  }

  Future<String?> _uploadRoomPhoto(
    int listingId,
    int roomId,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'room_photo${_photoExtension(filePath)}',
      ),
    });
    final response = await _client.post(
      ApiEndpoints.listingRoomPhoto(listingId, roomId),
      data: formData,
    );
    final json = response.data as Map<String, dynamic>?;
    return json?['url'] as String?;
  }

  Future<List<Map<String, dynamic>>> _getParkingJson(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingParking(listingId));
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _getContactsJson(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingContacts(listingId));
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  num? _parseDecimal(String value) {
    if (value.isEmpty) return null;
    return num.tryParse(value);
  }

  /// Backend stores `ConditionRating` as `decimal?`, which may serialize as
  /// an int, double, or string. The app models it as an int level (1-4).
  static int? _parseConditionRating(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.round();
    }
    return null;
  }

  /// Keeps the original file extension so the API's extension allow-list
  /// (`.jpg/.jpeg/.png/.webp`) validates the actual content type.
  static String _photoExtension(String filePath) {
    final dot = filePath.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final ext = filePath.substring(dot).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(ext) ? ext : '.jpg';
  }

  /// Resolves the condition category against `/api/condition-categories`
  /// instead of assuming id 1 exists. Falls back to 1 when offline.
  Future<int> _resolveConditionCategoryId() async {
    try {
      _conditionCategoriesCache ??= await _getConditionCategoriesJson();
      if (_conditionCategoriesCache!.isNotEmpty) {
        return _conditionCategoriesCache!.first['id'] as int;
      }
    } catch (e) {
      developer.log('Condition categories lookup failed, using 1: $e');
    }
    return 1;
  }

  Future<List<Map<String, dynamic>>> _getConditionCategoriesJson() async {
    final response = await _client.get(ApiEndpoints.conditionCategories);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// Maps feature descriptions to predefined `/api/features` ids
  /// (case-insensitive). Descriptions with no match stay custom features.
  Future<Map<String, int>> _featureIdByName() async {
    if (_featureIdByNameCache != null) return _featureIdByNameCache!;
    final map = <String, int>{};
    try {
      final response = await _client.get(ApiEndpoints.features);
      for (final e in (response.data as List).cast<Map<String, dynamic>>()) {
        final description = (e['description'] as String?)?.trim().toLowerCase();
        final id = e['id'] as int?;
        if (description != null && description.isNotEmpty && id != null) {
          map.putIfAbsent(description, () => id);
        }
      }
    } catch (e) {
      developer.log('Features lookup failed, using custom features: $e');
    }
    _featureIdByNameCache = map;
    return map;
  }

  /// Splits room features into predefined ids (link) vs free text (custom),
  /// resolving descriptions against the lookup so locally-created features
  /// link correctly instead of always becoming custom features.
  Future<({Set<int> linkedIds, Set<String> customDescriptions})>
  _partitionFeatures(List<RoomFeature> features) async {
    final linkedIds = <int>{};
    final customDescriptions = <String>{};
    Map<String, int>? lookup;
    for (final feature in features) {
      if (feature.featureId != null) {
        linkedIds.add(feature.featureId!);
      } else {
        lookup ??= await _featureIdByName();
        final resolved = lookup[feature.description.trim().toLowerCase()];
        if (resolved != null) {
          linkedIds.add(resolved);
        } else {
          customDescriptions.add(feature.description);
        }
      }
    }
    return (linkedIds: linkedIds, customDescriptions: customDescriptions);
  }

  bool _contactHasData(Contact contact) {
    return contact.fullName.isNotEmpty ||
        contact.idNumber.isNotEmpty ||
        contact.companyName.isNotEmpty ||
        contact.companyRegistrationNumber.isNotEmpty ||
        contact.mobilePhone.isNotEmpty ||
        contact.emailAddress.isNotEmpty ||
        contact.role.isNotEmpty;
  }
}
