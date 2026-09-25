import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dto/listing_dtos.dart';
import '../../../../core/network/photo_urls.dart';
import '../models/contact.dart';
import '../models/enums/outdoor_extra.dart';
import '../models/listing_document.dart';
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

  /// Bytes for photos that have no filesystem path to re-read.
  ///
  /// On the web `image_picker` returns a blob URL, not a file path, and
  /// `MultipartFile.fromFile` throws (`dart:io` is unavailable there). The UI
  /// therefore caches `XFile.readAsBytes()` here at pick time, keyed by the
  /// path stored in state, so uploads can use `MultipartFile.fromBytes`.
  final Map<String, ({Uint8List bytes, String filename})> pendingPhotoBytes =
      {};

  /// Caches photo bytes for a later upload. [filename] should be the
  /// original picked file name so the server's extension allow-list still
  /// validates (blob URLs carry no extension).
  void cachePhotoBytes(String path, Uint8List bytes, {String? filename}) {
    pendingPhotoBytes[path] = (
      bytes: bytes,
      filename: filename ?? 'photo${_photoExtension(path)}',
    );
  }

  void evictPhotoBytes(String path) => pendingPhotoBytes.remove(path);

  /// Builds the `file` multipart entry for [filePath], preferring cached
  /// bytes (web / already-in-memory) over reading from disk.
  Future<MultipartFile> _photoMultipartFile(String filePath) async {
    final cached = pendingPhotoBytes[filePath];
    if (cached != null) {
      return MultipartFile.fromBytes(cached.bytes, filename: cached.filename);
    }
    return MultipartFile.fromFile(
      filePath,
      filename: 'photo${_photoExtension(filePath)}',
    );
  }

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
    // The API returns a JSON array on success, but an auth or server failure
    // can surface here as a non-list body (e.g. ProblemDetails). Fail loudly
    // with a mappable Failure instead of a bare TypeError so the home screen
    // can show the real cause.
    final data = response.data;
    if (data is! List) {
      throw const ValidationFailure('Unexpected response from the server.');
    }
    final listings = <ListingSummaryDto>[];
    for (final e in data) {
      final j = e as Map<String, dynamic>;
      // `id` is the only field a card cannot do without — skip rows that
      // lack it instead of crashing the whole list.
      final id = (j['id'] as num?)?.toInt();
      if (id == null) continue;
      listings.add(
        ListingSummaryDto(
          id: id,
          // `ReferenceNumber` is nullable in the database, so tolerate nulls
          // rather than crashing the home screen when one slips through.
          referenceNumber: j['referenceNumber'] as String? ?? '',
          p24Ref: j['p24Ref'] as String?,
          houseScore: (j['houseScore'] as num?)?.toDouble(),
          archivedAt: j['archivedAt'] != null
              ? DateTime.tryParse(j['archivedAt'] as String)
              : null,
          ownerNames: ((j['ownerNames'] as String?) ?? '')
              .split('|')
              .map((n) => n.trim())
              .where((n) => n.isNotEmpty)
              .toList(),
          propertyTypeId: (j['propertyTypeId'] as num?)?.toInt() ?? 0,
          listingValuationId: (j['listingValuationId'] as num?)?.toInt(),
          listDate: j['listDate'] != null
              ? DateTime.tryParse(j['listDate'] as String)
              : null,
          status: j['status'] as String? ?? 'incomplete',
          createdAt:
              DateTime.tryParse(j['createdAt'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
              DateTime.now(),
          // Enriched summaries (address, owner, photo, room count) are served
          // inline by newer API builds; absent on older ones — all optional.
          streetNumber: j['streetNumber'] as String?,
          street: j['street'] as String?,
          suburb: j['suburb'] as String?,
          city: j['city'] as String?,
          primaryOwnerName: j['primaryOwnerName'] as String?,
          primaryPhotoUrl: j['primaryPhotoUrl'] as String?,
          roomCount: (j['roomCount'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return listings;
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
      savedHouseScore: (j['houseScore'] as num?)?.toDouble(),
      houseScoreIsManual: j['houseScoreIsManual'] as bool? ?? false,
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
          score: (condition?['score'] as num?)?.toDouble(),
          features: [...features, ...customFeatures],
          notes: condition?['notes'] as String? ?? '',
          photos: _parseRoomPhotos(r),
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
        sewage: runningCosts?['sewage']?.toString() ?? '',
        refuse: runningCosts?['refuse']?.toString() ?? '',
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
    if (state.propertyRunningCosts.sewage.isNotEmpty) {
      data['sewage'] = _parseDecimal(state.propertyRunningCosts.sewage);
    }
    if (state.propertyRunningCosts.refuse.isNotEmpty) {
      data['refuse'] = _parseDecimal(state.propertyRunningCosts.refuse);
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
    final photos = await _uploadPendingRoomPhotos(
      listingId,
      createdId,
      room.photos,
    );

    // Rating, score and notes share one Condition row; write it when any of
    // them is set (notes alone used to be dropped for an unrated room).
    if (room.conditionRating != null ||
        room.score != null ||
        room.notes.isNotEmpty) {
      await _upsertRoomCondition(
        listingId,
        createdId,
        conditionRating: room.conditionRating,
        score: room.score,
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

    return room.copyWith(id: createdId.toString(), photos: photos);
  }

  Future<Room> _syncExistingRoom(
    int listingId,
    int apiId,
    Room room,
    Map<String, dynamic> existing,
  ) async {
    await _updateRoom(listingId, apiId, room);

    // Photos the agent removed are deleted; new shots are uploaded.
    final keptIds = room.photos.map((p) => p.id).whereType<int>().toSet();
    for (final existingPhoto in _parseRoomPhotos(existing)) {
      final id = existingPhoto.id;
      if (id != null && !keptIds.contains(id)) {
        await _client.delete(
          ApiEndpoints.listingRoomPhotoById(listingId, apiId, id),
        );
      }
    }
    final photos = await _uploadPendingRoomPhotos(
      listingId,
      apiId,
      room.photos,
    );

    final existingCondition = existing['condition'] as Map<String, dynamic>?;
    if (room.conditionRating !=
            _parseConditionRating(existingCondition?['conditionRating']) ||
        room.score != (existingCondition?['score'] as num?)?.toDouble() ||
        room.notes != (existingCondition?['notes'] as String? ?? '')) {
      await _upsertRoomCondition(
        listingId,
        apiId,
        conditionRating: room.conditionRating,
        score: room.score,
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

    return room.copyWith(photos: photos);
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

  /// Moves a listing to the archive, or back to the active list.
  Future<void> setArchived(int listingId, {required bool archived}) async {
    await _client.put(
      ApiEndpoints.listingArchive(listingId),
      data: {'archived': archived},
    );
  }

  /// Saves the house score (a percentage, or null to clear it).
  Future<void> updateHouseScore(
    int listingId, {
    required double? score,
    required bool isManual,
  }) async {
    await _client.put(
      ApiEndpoints.listingHouseScore(listingId),
      data: {'score': score, 'isManual': isManual},
    );
  }

  Future<void> deleteListing(int listingId) async {
    await _client.delete(ApiEndpoints.listing(listingId));
    developer.log('Listing deleted: ID=$listingId');
  }

  /// Listing-level (exterior) photos, ordered primary-first by the API.
  Future<List<Map<String, dynamic>>> getListingPhotos(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingPhotos(listingId));
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// Uploads one exterior photo; returns the created photo JSON
  /// (`id`, `url`, `isPrimary`, ...). The URL is absolute (R2) or
  /// app-relative `/uploads/...` (temporary local storage).
  Future<Map<String, dynamic>> uploadListingPhoto(
    int listingId,
    String filePath, {
    Uint8List? bytes,
    String? filename,
  }) async {
    if (bytes != null) cachePhotoBytes(filePath, bytes, filename: filename);
    final formData = FormData.fromMap({
      'file': await _photoMultipartFile(filePath),
    });
    final response = await _client.post(
      ApiEndpoints.listingPhotos(listingId),
      data: formData,
    );
    pendingPhotoBytes.remove(filePath);
    return response.data as Map<String, dynamic>;
  }

  Future<void> setPrimaryListingPhoto(int listingId, int photoId) async {
    await _client.put(ApiEndpoints.listingPhotoPrimary(listingId, photoId));
  }

  Future<void> deleteListingPhoto(int listingId, int photoId) async {
    await _client.delete(ApiEndpoints.listingPhoto(listingId, photoId));
  }

  Future<List<ListingDocument>> getListingDocuments(int listingId) async {
    final response = await _client.get(
      ApiEndpoints.listingDocuments(listingId),
    );
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .map(ListingDocument.fromJson)
        .toList();
  }

  Future<ListingDocument> uploadListingDocument(
    int listingId,
    ListingDocument document,
  ) async {
    final formData = FormData.fromMap({
      'category': document.category.apiValue,
      'file': await MultipartFile.fromFile(
        document.localPath!,
        filename: document.fileName,
      ),
    });
    final response = await _client.post(
      ApiEndpoints.listingDocuments(listingId),
      data: formData,
    );
    return ListingDocument.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteListingDocument(int listingId, int documentId) async {
    await _client.delete(ApiEndpoints.listingDocument(listingId, documentId));
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
    // The cover photo is kept in step by the API as photos are added and
    // removed, so it is not sent here.
    if (room.roomTypeOther != null) data['roomTypeOther'] = room.roomTypeOther;
    await _client.put(ApiEndpoints.listingRoom(listingId, roomId), data: data);
  }

  Future<void> _upsertRoomCondition(
    int listingId,
    int roomId, {
    int? conditionRating,
    double? score,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'conditionCategoryId': await _resolveConditionCategoryId(),
      // Always sent: the API upsert overwrites the row, so omitting it would
      // clear a stored score.
      'score': score,
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

  /// Room photos from a room DTO: the `photos` list, or — from an API that
  /// predates multiple photos — the single `photoUrl` as the only photo.
  static List<RoomPhoto> _parseRoomPhotos(Map<String, dynamic> room) {
    final list = room['photos'] as List<dynamic>?;
    if (list != null) {
      final photos = list.cast<Map<String, dynamic>>().toList()
        ..sort(
          (a, b) => ((a['sortOrder'] as int?) ?? 0).compareTo(
            (b['sortOrder'] as int?) ?? 0,
          ),
        );
      return [
        for (final p in photos)
          RoomPhoto(id: p['id'] as int?, path: p['url'] as String),
      ];
    }
    final legacy = room['photoUrl'] as String?;
    return legacy == null ? const [] : [RoomPhoto(path: legacy)];
  }

  /// Uploads every photo still held as a local file and returns the list with
  /// server ids and URLs in their place. A failed upload stays local so the
  /// next save retries it.
  Future<List<RoomPhoto>> _uploadPendingRoomPhotos(
    int listingId,
    int roomId,
    List<RoomPhoto> photos,
  ) async {
    final result = <RoomPhoto>[];
    for (final photo in photos) {
      if (photo.isUploaded || isRemotePhoto(photo.path)) {
        result.add(photo);
        continue;
      }
      try {
        final formData = FormData.fromMap({
          'file': await _photoMultipartFile(photo.path),
        });
        final response = await _client.post(
          ApiEndpoints.listingRoomPhotos(listingId, roomId),
          data: formData,
        );
        pendingPhotoBytes.remove(photo.path);
        final json = response.data as Map<String, dynamic>;
        result.add(RoomPhoto(id: json['id'] as int?, path: json['url'] as String));
      } catch (e) {
        developer.log('Room photo upload failed: $e');
        result.add(photo);
      }
    }
    return result;
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
