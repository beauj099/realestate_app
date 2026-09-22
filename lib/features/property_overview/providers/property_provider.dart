import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/photo_urls.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../data/default_features.dart';
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
  /// Compares by identity: any mutation produces a new [PropertyState], so a
  /// value typed and then retyped identically still counts as a change. That
  /// errs toward asking before discarding, which is the safe direction.
  bool get hasUnsavedSectionChanges =>
      _sectionSnapshot != null && !identical(_sectionSnapshot, state);

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
    }
    return result.id;
  }

  Future<void> loadListing(int id) async {
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
        developer.log('Listing photos load failed: $e');
      }
      // Documents also have their own endpoint. An API without it (older
      // build) just leaves the list empty.
      try {
        final documents = await _repository.getListingDocuments(id);
        if (!ref.mounted) return;
        state = state.copyWith(documents: documents);
      } catch (e) {
        developer.log('Listing documents load failed: $e');
      }
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
      final syncedRooms = await _repository.upsertRooms(id, state.rooms);
      await _repository.upsertParking(id, state.parking);
      await _repository.upsertOutdoorFeatures(id, state.outdoorFeatures);
      if (ref.mounted) state = state.copyWith(rooms: syncedRooms);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: mapFailure(e).message);
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
    final defaults = roomDefaultFeatures[roomTypeId] ?? [];
    final newRoom = Room(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      roomTypeId: roomTypeId,
      features: defaults.map((d) => RoomFeature(description: d)).toList(),
    );
    state = state.copyWith(rooms: [...state.rooms, newRoom]);
    return newRoom.id;
  }

  void removeRoom(String roomId) {
    state = state.copyWith(
      rooms: state.rooms.where((r) => r.id != roomId).toList(),
    );
  }

  void addParking(int parkingTypeId) {
    final current = List<ListingParking>.from(state.parking);
    final existingIdx = current.indexWhere(
      (p) => p.parkingTypeId == parkingTypeId,
    );
    if (existingIdx >= 0) {
      current[existingIdx] = current[existingIdx].copyWith(
        quantity: current[existingIdx].quantity + 1,
      );
    } else {
      current.add(
        ListingParking(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          parkingTypeId: parkingTypeId,
          quantity: 1,
        ),
      );
    }
    state = state.copyWith(parking: current);
  }

  void removeParking(int parkingTypeId) {
    final current = List<ListingParking>.from(state.parking);
    current.removeWhere((p) => p.parkingTypeId == parkingTypeId);
    state = state.copyWith(parking: current);
  }

  void decrementParking(int parkingTypeId) {
    final current = List<ListingParking>.from(state.parking);
    final idx = current.indexWhere((p) => p.parkingTypeId == parkingTypeId);
    if (idx < 0) return;
    if (current[idx].quantity <= 1) {
      current.removeAt(idx);
    } else {
      current[idx] = current[idx].copyWith(quantity: current[idx].quantity - 1);
    }
    state = state.copyWith(parking: current);
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

  void addOutdoorFeature(String feature) {
    final current = List<String>.from(state.outdoorFeatures);
    if (!current.contains(feature)) {
      current.add(feature);
    }
    state = state.copyWith(outdoorFeatures: current);
  }

  void removeOutdoorFeature(String feature) {
    final current = List<String>.from(state.outdoorFeatures);
    current.remove(feature);
    state = state.copyWith(outdoorFeatures: current);
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
    String? photoUrl,
    Uint8List? photoBytes,
    String? photoFilename,
  }) {
    if (photoUrl != null && photoBytes != null) {
      _repository.cachePhotoBytes(
        photoUrl,
        photoBytes,
        filename: photoFilename,
      );
    }
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        return room.copyWith(
          conditionRating: conditionRating,
          features: features,
          hiddenFeatures: hiddenFeatures,
          notes: notes,
          photoUrl: photoUrl,
        );
      }
      return room;
    }).toList();
    state = state.copyWith(rooms: updatedRooms);
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

  void hideOutdoorFeature(String feature) {
    final hidden = List<String>.from(state.outdoorHiddenFeatures);
    if (!hidden.contains(feature)) hidden.add(feature);
    final features = List<String>.from(state.outdoorFeatures);
    features.remove(feature);
    state = state.copyWith(
      outdoorFeatures: features,
      outdoorHiddenFeatures: hidden,
    );
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
    _exteriorPhotoIds.clear();
    _repository.pendingPhotoBytes.clear();
    state = PropertyState(
      rooms: const [],
      parking: const [],
      propertyTypeId: 0,
    );
  }
}
