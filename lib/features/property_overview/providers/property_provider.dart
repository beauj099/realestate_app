import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/photo_urls.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../data/models/contact.dart';
import '../data/models/listing_document.dart';
import '../data/models/listing_parking.dart';
import '../data/models/property_state.dart';
import '../data/models/room.dart';
import '../data/repositories/property_repository.dart';

final propertyRepositoryProvider = Provider.autoDispose<PropertyRepository>((
  ref,
) {
  return PropertyRepository(ref.watch(apiClientProvider));
});

final propertyViewModelProvider =
    NotifierProvider.autoDispose<PropertyViewModel, PropertyState>(() {
      return PropertyViewModel();
    });

/// Parking types keyed by API id, with offline fallback labels matching the
/// last-known backend seed. The features screen prefers live API data.
const fallbackParkingTypes = {
  1: 'Single Garage',
  2: 'Double Garage',
  3: 'Triple Garage',
  4: 'Carport',
  5: 'Off-Street Parking',
  6: 'Undercover Parking',
};

final parkingTypesProvider = FutureProvider.autoDispose<Map<int, String>>((
  ref,
) async {
  try {
    final lookup = ref.watch(lookupApiServiceProvider);
    final types = await lookup.getParkingTypes();
    if (types.isEmpty) return fallbackParkingTypes;
    return {for (final t in types) t.id: t.description};
  } catch (_) {
    return fallbackParkingTypes;
  }
});

class PropertyViewModel extends Notifier<PropertyState> {
  late final PropertyRepository _repository;

  /// State captured when a section screen opened.
  ///
  /// Every section edits the one shared [PropertyState], so leaving a screen
  /// without saving has to put the shared state back exactly as it was —
  /// otherwise the overview would show edits that were never persisted.
  PropertyState? _sectionSnapshot;

  /// Server-side ids for uploaded exterior photos, keyed by their URL.
  /// Local (not yet uploaded) paths have no entry. Keeps the string-only
  /// [PropertyState.exteriorPhotos] usable with the photo endpoints, which
  /// address photos by id for primary/delete.
  final Map<String, int> _exteriorPhotoIds = {};

  /// True once the whole listing is known locally — created here, or loaded
  /// with its photos and documents. [discardIfEmpty] relies on it: a listing
  /// that only *looks* empty because a request failed must never be deleted.
  bool _fullyLoaded = false;

  @override
  PropertyState build() {
    _repository = ref.watch(propertyRepositoryProvider);
    return PropertyState(rooms: const [], parking: const []);
  }

  /// Marks the start of an editing session for one section screen.
  void beginSectionEdit() {
    _sectionSnapshot = state;
  }

  /// Rolls the shared state back to the snapshot taken on entry.
  void discardSectionEdit() {
    final snapshot = _sectionSnapshot;
    _sectionSnapshot = null;
    if (snapshot != null) state = snapshot;
  }

  /// Accepts the current state as the new baseline after a successful save.
  void commitSectionEdit() {
    _sectionSnapshot = null;
  }

  /// Whether anything changed since the section screen opened.
  ///
  /// Compares content, not identity, so switching the owner type with nothing
  /// typed, or typing a value and deleting it again, is not a change and does
  /// not trigger the discard prompt.
  bool get hasUnsavedSectionChanges {
    final snapshot = _sectionSnapshot;
    return snapshot != null && !snapshot.sameContentAs(state);
  }

  Future<int> createNewListing() async {
    final result = await _repository.createListing(
      state.propertyTypeId > 0 ? state.propertyTypeId : null,
      p24Ref: state.p24Ref,
    );
    if (ref.mounted) {
      state = state.copyWith(
        listingId: result.id,
        referenceNumber: result.referenceNumber,
      );
      _fullyLoaded = true;
    }
    return result.id;
  }

  /// Deletes the listing when the agent leaves it without capturing anything
  /// worth keeping (see [PropertyState.hasMeaningfulContent]), so an untouched
  /// "Add Property" never lingers on the home screen as an empty card.
  ///
  /// Returns true when the listing was discarded.
  Future<bool> discardIfEmpty() async {
    final id = state.listingId;
    if (id == null || !_fullyLoaded || state.hasMeaningfulContent) {
      return false;
    }
    try {
      await _repository.deleteListing(id);
      return true;
    } catch (e) {
      developer.log('Discarding empty listing failed: $e');
      return false;
    }
  }

  Future<void> loadListing(int id) async {
    _fullyLoaded = false;
    var complete = true;
    try {
      final loaded = await _repository.loadListing(id);
      if (!ref.mounted) return;
      state = loaded;
      // Exterior photos live on their own endpoint; the detail payload
      // does not include them.
      try {
        final photos = await _repository.getListingPhotos(id);
        if (!ref.mounted) return;
        _exteriorPhotoIds.clear();
        for (final p in photos) {
          _exteriorPhotoIds[p['url'] as String] = p['id'] as int;
        }
        state = state.copyWith(exteriorPhotos: _exteriorPhotoIds.keys.toList());
      } catch (e) {
        complete = false;
        developer.log('Listing photos load failed: $e');
      }
      // Documents also have their own endpoint. An API without it (older
      // build) just leaves the list empty.
      try {
        final documents = await _repository.getListingDocuments(id);
        if (!ref.mounted) return;
        state = state.copyWith(documents: documents);
      } catch (e) {
        complete = false;
        developer.log('Listing documents load failed: $e');
      }
      _fullyLoaded = complete;
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  Future<void> savePropertyType() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.updatePropertyType(
        id,
        state.propertyTypeId,
        p24Ref: state.p24Ref,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  void updateP24Ref(String? value) {
    final trimmed = value?.trim();
    state = state.copyWith(
      p24Ref: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }

  Future<void> saveAddress() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.upsertAddress(id, state);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  Future<void> saveBuildingInfo() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.upsertBuildingInfo(id, state);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  Future<void> savePropertyFeatures() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      // A parking type counted down to zero is how the agent removes it.
      final parking = state.parking.where((p) => p.quantity > 0).toList();
      final syncedRooms = await _repository.upsertRooms(id, state.rooms);
      await _repository.upsertParking(id, parking);
      if (ref.mounted) state = state.copyWith(parking: parking);
      await _repository.upsertOutdoorFeatures(id, state.outdoorFeatures);
      if (ref.mounted) state = state.copyWith(rooms: syncedRooms);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
      return;
    }
    await _saveSuggestedHouseScore();
  }

  /// Keeps the saved house score in step with the room scores until the
  /// agent sets their own. A failure here does not fail the section save —
  /// the next save tries again.
  Future<void> _saveSuggestedHouseScore() async {
    final id = state.listingId;
    if (id == null || state.houseScoreIsManual) return;
    final suggested = state.suggestedHouseScore;
    if (suggested == state.savedHouseScore) return;
    try {
      await _repository.updateHouseScore(
        id,
        score: suggested,
        isManual: false,
      );
      if (ref.mounted) state = state.copyWith(savedHouseScore: suggested);
    } catch (e) {
      developer.log('Saving suggested house score failed: $e');
    }
  }

  /// Saves the agent's own house score, or with [score] null goes back to
  /// the app's suggestion. Returns an error message, or null on success.
  Future<String?> setHouseScore(double? score) async {
    final id = state.listingId;
    if (id == null) return const NetworkFailure().message;
    final isManual = score != null;
    final value = score ?? state.suggestedHouseScore;
    try {
      await _repository.updateHouseScore(
        id,
        score: value,
        isManual: isManual,
      );
      if (ref.mounted) {
        state = state.copyWith(
          savedHouseScore: value,
          houseScoreIsManual: isManual,
        );
      }
      return null;
    } catch (e) {
      return mapFailure(e).message;
    }
  }

  /// Persists pricing and commission only.
  ///
  /// Split from [saveRunningCosts] when valuation moved to its own section:
  /// saving Expenses used to post an empty valuation record alongside it,
  /// before the agent had agreed a price.
  Future<void> saveValuation() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.upsertValuation(id, state);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  /// Persists the Expenses section: the monthly running costs, then the
  /// supporting documents — removals are deleted and newly picked files
  /// uploaded. A document that fails to upload stays queued for the next save.
  Future<void> saveRunningCosts() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.upsertRunningCosts(id, state);

      for (final docId in state.removedDocumentIds) {
        await _repository.deleteListingDocument(id, docId);
        if (!ref.mounted) return;
        state = state.copyWith(
          removedDocumentIds: state.removedDocumentIds
              .where((d) => d != docId)
              .toList(),
        );
      }

      Object? uploadError;
      for (final doc in state.documents.where((d) => !d.isUploaded)) {
        try {
          final uploaded = await _repository.uploadListingDocument(id, doc);
          if (!ref.mounted) return;
          state = state.copyWith(
            documents: [
              for (final d in state.documents) identical(d, doc) ? uploaded : d,
            ],
          );
        } catch (e) {
          developer.log('Document upload failed: $e');
          uploadError ??= e;
        }
      }
      if (uploadError != null) throw uploadError;
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  void addDocument(ListingDocument document) {
    state = state.copyWith(documents: [...state.documents, document]);
  }

  /// Takes [document] off the list; an uploaded one is deleted from the API
  /// on the next save, so backing out of Expenses brings it back.
  void removeDocument(ListingDocument document) {
    state = state.copyWith(
      documents: state.documents.where((d) => !identical(d, document)).toList(),
      removedDocumentIds: [
        ...state.removedDocumentIds,
        if (document.id != null) document.id!,
      ],
    );
  }

  Future<void> saveContacts() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      final syncedContacts = await _repository.upsertContacts(
        id,
        state.primaryContact,
        state.coContacts,
      );
      if (ref.mounted) {
        final includedPrimary = state.primaryContact.fullName.isNotEmpty;
        state = state.copyWith(
          primaryContact: includedPrimary && syncedContacts.isNotEmpty
              ? syncedContacts.first
              : const Contact(),
          coContacts: includedPrimary
              ? (syncedContacts.length > 1 ? syncedContacts.sublist(1) : [])
              : syncedContacts,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
  }

  void selectPropertyType(int id) {
    state = state.copyWith(propertyTypeId: id);
  }

  void updateAddress({
    String? streetNumber,
    String? street,
    String? unitNumber,
    String? suburb,
    String? city,
    String? province,
    String? country,
    String? postalCode,
  }) {
    state = state.copyWith(
      streetNumber: streetNumber,
      street: street,
      unitNumber: unitNumber,
      suburb: suburb,
      city: city,
      province: province,
      country: country,
      postalCode: postalCode,
    );
  }

  void updateCoordinates({double? latitude, double? longitude}) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void clearCoordinates() {
    state = state.copyWith(latitude: null, longitude: null);
  }

  void updateIdentifiers({String? estateName, String? erfNumber}) {
    state = state.copyWith(estateName: estateName, erfNumber: erfNumber);
  }

  void updateTechnicalSpecs({
    String? erfSize,
    String? floorArea,
    String? constructionYear,
  }) {
    state = state.copyWith(
      erfSize: erfSize,
      floorArea: floorArea,
      constructionYear: constructionYear,
    );
  }

  void selectFacingId(int? id) {
    state = state.copyWith(facingId: id);
  }

  void selectZoningId(int? id) {
    state = state.copyWith(zoningId: id);
  }

  /// Adds a room and returns its local id so the caller can open it straight
  /// away — picking a room type is the start of describing it, not the end.
  String addCustomRoom(String name, int roomTypeId) {
    // Starts with nothing ticked: every feature is something the agent saw.
    final newRoom = Room(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      roomTypeId: roomTypeId,
    );
    state = state.copyWith(rooms: [...state.rooms, newRoom]);
    return newRoom.id;
  }

  void removeRoom(String roomId) {
    state = state.copyWith(
      rooms: state.rooms.where((r) => r.id != roomId).toList(),
    );
  }

  /// Adds each parking type not already listed, starting at one bay.
  void addParkingTypes(Iterable<int> parkingTypeIds) {
    final current = List<ListingParking>.from(state.parking);
    for (final typeId in parkingTypeIds) {
      if (current.any((p) => p.parkingTypeId == typeId)) continue;
      current.add(
        ListingParking(
          id: '${DateTime.now().microsecondsSinceEpoch}-$typeId',
          parkingTypeId: typeId,
          quantity: 1,
        ),
      );
    }
    state = state.copyWith(parking: current);
  }

  /// Sets how many of a parking type there are. Zero keeps the row on screen
  /// (so a mis-tap is easy to undo) and it is dropped when the section saves.
  void setParkingQuantity(int parkingTypeId, int quantity) {
    state = state.copyWith(
      parking: [
        for (final p in state.parking)
          p.parkingTypeId == parkingTypeId
              ? p.copyWith(quantity: quantity < 0 ? 0 : quantity)
              : p,
      ],
    );
  }

  /// Replaces the ticked features within one outdoor category — [options] is
  /// everything that category offers, [selected] what the agent left ticked.
  void setOutdoorFeaturesInCategory(
    Iterable<String> options,
    Iterable<String> selected,
  ) {
    final optionSet = options.toSet();
    final kept = state.outdoorFeatures
        .where((f) => !optionSet.contains(f))
        .toList();
    state = state.copyWith(
      outdoorFeatures: [
        ...kept,
        ...selected.where((f) => !kept.contains(f)),
      ],
    );
  }

  void addExteriorPhoto(String path, {Uint8List? bytes, String? filename}) {
    if (state.exteriorPhotos.contains(path)) return;
    if (bytes != null) {
      _repository.cachePhotoBytes(path, bytes, filename: filename);
    }
    state = state.copyWith(exteriorPhotos: [...state.exteriorPhotos, path]);
  }

  void removeExteriorPhoto(String path) {
    // Fire-and-forget is fine here: local state updates immediately and the
    // server delete is best-effort (a mismatch self-heals on the next load).
    unawaited(removeExteriorPhotoAndSync(path));
  }

  /// Removes [path] locally and deletes it server-side when uploaded.
  Future<void> removeExteriorPhotoAndSync(String path) async {
    final photoId = _exteriorPhotoIds.remove(path);
    _repository.evictPhotoBytes(path);
    state = state.copyWith(
      exteriorPhotos: state.exteriorPhotos.where((p) => p != path).toList(),
    );
    final listingId = state.listingId;
    if (listingId == null || photoId == null) return;
    try {
      await _repository.deleteListingPhoto(listingId, photoId);
    } catch (e) {
      developer.log('Listing photo delete failed: $e');
    }
  }

  /// Promotes [path] to the hero shot by moving it to the front of the list.
  void setMainExteriorPhoto(String path) {
    unawaited(setMainExteriorPhotoAndSync(path));
  }

  /// Reorders locally and marks the photo primary server-side when uploaded.
  Future<void> setMainExteriorPhotoAndSync(String path) async {
    if (!state.exteriorPhotos.contains(path)) return;
    state = state.copyWith(
      exteriorPhotos: [path, ...state.exteriorPhotos.where((p) => p != path)],
    );
    final listingId = state.listingId;
    final photoId = _exteriorPhotoIds[path];
    if (listingId == null || photoId == null) return;
    try {
      await _repository.setPrimaryListingPhoto(listingId, photoId);
    } catch (e) {
      developer.log('Listing photo primary failed: $e');
    }
  }

  /// Uploads a freshly picked exterior photo, swapping the local path for
  /// the server URL on success. Returns false when the upload failed — the
  /// local path stays in place so [saveExteriorPhotos] can retry at submit.
  Future<bool> uploadExteriorPhoto(String localPath) async {
    final listingId = state.listingId;
    if (listingId == null) return false;
    try {
      final created = await _repository.uploadListingPhoto(
        listingId,
        localPath,
      );
      final url = created['url'] as String?;
      final id = created['id'] as int?;
      if (url == null || id == null) return false;
      if (!ref.mounted) return false;
      _exteriorPhotoIds[url] = id;
      state = state.copyWith(
        exteriorPhotos: [
          for (final p in state.exteriorPhotos) p == localPath ? url : p,
        ],
      );
      return true;
    } catch (e) {
      developer.log('Listing photo upload failed: $e');
      return false;
    }
  }

  /// Uploads any exterior photos still held as local paths and repairs the
  /// hero shot when the server primary drifted (e.g. an earlier primary PUT
  /// failed). Called before submit so a capture-time failure is retried.
  Future<void> saveExteriorPhotos() async {
    final listingId = state.listingId;
    if (listingId == null) return;
    final photos = List<String>.from(state.exteriorPhotos);
    var changed = false;
    for (var i = 0; i < photos.length; i++) {
      if (isRemotePhoto(photos[i])) continue;
      try {
        final created = await _repository.uploadListingPhoto(
          listingId,
          photos[i],
        );
        final url = created['url'] as String?;
        final id = created['id'] as int?;
        if (url == null || id == null) continue;
        _exteriorPhotoIds[url] = id;
        photos[i] = url;
        changed = true;
      } catch (e) {
        developer.log('Listing photo upload failed: $e');
      }
    }
    if (changed && ref.mounted) {
      state = state.copyWith(exteriorPhotos: photos);
    }
    try {
      final server = await _repository.getListingPhotos(listingId);
      if (!ref.mounted) return;
      _exteriorPhotoIds.clear();
      for (final p in server) {
        _exteriorPhotoIds[p['url'] as String] = p['id'] as int;
      }
      final primary = server.where((p) => p['isPrimary'] == true).toList();
      if (photos.isNotEmpty &&
          (primary.isEmpty || primary.first['url'] != photos.first)) {
        final photoId = _exteriorPhotoIds[photos.first];
        if (photoId != null) {
          await _repository.setPrimaryListingPhoto(listingId, photoId);
        }
      }
    } catch (e) {
      developer.log('Listing photo sync failed: $e');
    }
  }

  void selectRoomForEditing(String? roomId) {
    state = state.copyWith(selectedRoomId: roomId);
  }

  void updateRoomDetails({
    required String roomId,
    int? conditionRating,
    List<RoomFeature>? features,
    List<String>? hiddenFeatures,
    String? notes,
  }) {
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        return room.copyWith(
          conditionRating: conditionRating,
          features: features,
          hiddenFeatures: hiddenFeatures,
          notes: notes,
        );
      }
      return room;
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
  }

  /// Adds freshly taken photos to a room, up to [Room.maxPhotos]. They stay
  /// on the device until the Property Features section is saved.
  void addRoomPhotos(
    String roomId,
    List<({String path, Uint8List? bytes, String? filename})> shots,
  ) {
    state = state.copyWith(
      rooms: [
        for (final room in state.rooms)
          if (room.id != roomId)
            room
          else
            room.copyWith(
              photos: [
                ...room.photos,
                for (final shot in shots.take(
                  Room.maxPhotos - room.photos.length,
                ))
                  RoomPhoto(path: shot.path),
              ],
            ),
      ],
    );
    for (final shot in shots) {
      final bytes = shot.bytes;
      if (bytes != null) {
        _repository.cachePhotoBytes(shot.path, bytes, filename: shot.filename);
      }
    }
  }

  /// Removes one photo; an uploaded one is deleted from the API on save.
  void removeRoomPhoto(String roomId, String path) {
    state = state.copyWith(
      rooms: [
        for (final room in state.rooms)
          room.id == roomId
              ? room.copyWith(
                  photos: room.photos.where((p) => p.path != path).toList(),
                )
              : room,
      ],
    );
  }

  /// Replaces a room's ticked features within one group — [options] is
  /// everything the group offers, [selected] what the agent left ticked.
  /// Features that stay ticked keep their saved ids.
  void setRoomFeaturesInGroup(
    String roomId,
    Iterable<String> options,
    Iterable<String> selected,
  ) {
    final optionSet = options.toSet();
    state = state.copyWith(
      rooms: [
        for (final room in state.rooms)
          if (room.id != roomId)
            room
          else
            room.copyWith(
              features: [
                for (final f in room.features)
                  if (!optionSet.contains(f.description) ||
                      selected.contains(f.description))
                    f,
                for (final name in selected)
                  if (!room.features.any((f) => f.description == name))
                    RoomFeature(description: name),
              ],
            ),
      ],
    );
  }

  /// Sets or, with null, clears a room's 0–10 score.
  void setRoomScore(String roomId, double? score) {
    state = state.copyWith(
      rooms: [
        for (final room in state.rooms)
          room.id == roomId ? room.copyWith(score: score) : room,
      ],
    );
  }

  void hideFeatureInRoom(String roomId, String feature) {
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        final hidden = List<String>.from(room.hiddenFeatures);
        final features = List<RoomFeature>.from(room.features);
        if (!hidden.contains(feature)) hidden.add(feature);
        features.removeWhere((f) => f.description == feature);
        return room.copyWith(hiddenFeatures: hidden, features: features);
      }
      return room;
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
  }

  void renameRoom(String roomId, String newName) {
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) return room.copyWith(name: newName);
      return room;
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
  }

  void addFeatureToRoom(String roomId, String feature) {
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        final currentFeatures = List<RoomFeature>.from(room.features);
        if (!currentFeatures.any((f) => f.description == feature)) {
          currentFeatures.add(RoomFeature(description: feature));
        }
        return room.copyWith(features: currentFeatures);
      }
      return room;
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
  }

  void removeFeatureFromRoom(String roomId, String feature) {
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        final currentFeatures = List<RoomFeature>.from(room.features);
        currentFeatures.removeWhere((f) => f.description == feature);
        return room.copyWith(features: currentFeatures);
      }
      return room;
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
  }

  void updateValuation({
    String? ownersNetPrice,
    String? agentValuation,
    String? commissionPercent,
  }) {
    state = state.copyWith(
      listingValuation: state.listingValuation.copyWith(
        ownersNetPrice: ownersNetPrice,
        agentValuation: agentValuation,
        commissionPercent: commissionPercent,
      ),
    );
  }

  void updateRunningCosts({
    String? monthlyLevy,
    String? monthlyRates,
    String? electricity,
    String? water,
    String? sewage,
    String? refuse,
  }) {
    state = state.copyWith(
      propertyRunningCosts: state.propertyRunningCosts.copyWith(
        monthlyLevy: monthlyLevy,
        monthlyRates: monthlyRates,
        electricity: electricity,
        water: water,
        sewage: sewage,
        refuse: refuse,
      ),
    );
  }

  void updatePrimaryContact(Contact contact) {
    state = state.copyWith(primaryContact: contact);
  }

  void addCoContact() {
    final newContact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    state = state.copyWith(coContacts: [...state.coContacts, newContact]);
  }

  void updateCoContact(int index, Contact contact) {
    final updated = List<Contact>.from(state.coContacts);
    if (index >= 0 && index < updated.length) {
      updated[index] = contact;
      state = state.copyWith(coContacts: updated);
    }
  }

  void removeCoContact(String id) {
    state = state.copyWith(
      coContacts: state.coContacts.where((c) => c.id != id).toList(),
    );
  }

  /// Saves what the overview screen itself holds — the property type and any
  /// exterior photo still waiting to upload — so the agent can leave for the
  /// home screen knowing nothing is only on the device. Sections persist
  /// themselves on their own Save.
  ///
  /// Returns a message when something could not be saved, otherwise null.
  Future<String?> saveOverview() async {
    if (state.listingId == null) return const NetworkFailure().message;
    if (state.propertyTypeId > 0) {
      await savePropertyType();
      final error = state.errorMessage;
      if (error != null) return friendlySaveMessage(error, 'property type');
    }
    await saveExteriorPhotos();
    if (!ref.mounted) return null;
    final pending = state.exteriorPhotos.where((p) => !isRemotePhoto(p));
    if (pending.isNotEmpty) {
      return 'Some photos have not uploaded yet. Check your connection and '
          'try again.';
    }
    return null;
  }

  Future<bool> submitAndSave() async {
    final listingId = state.listingId;
    state = state.copyWith(errorMessage: null);

    if (listingId == null) {
      state = state.copyWith(errorMessage: const NetworkFailure().message);
      return false;
    }

    try {
      // Sections persist themselves when the agent taps Save, and anything
      // they backed out of was rolled back, so local state already matches the
      // server. Re-posting every section here would push state the agent chose
      // to discard and could clobber a newer server-side edit.
      //
      // Exterior photos are the exception: they upload in the background as
      // they are picked, so retry anything still held as a local path (a
      // capture-time failure) before submitting.
      await saveExteriorPhotos();
      await _repository.submitListing(listingId);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: mapFailure(e).message);
      return false;
    }
  }

  Future<void> deleteListing() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.deleteListing(id);
    } catch (e) {
      if (!ref.mounted) rethrow;
      state = state.copyWith(errorMessage: mapFailure(e).message);
      rethrow;
    }
  }

  void reset() {
    _fullyLoaded = false;
    _exteriorPhotoIds.clear();
    _repository.pendingPhotoBytes.clear();
    state = PropertyState(
      rooms: const [],
      parking: const [],
      propertyTypeId: 0,
    );
  }
}
