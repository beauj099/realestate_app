import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../data/default_features.dart';
import '../data/models/contact.dart';
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

class PropertyViewModel extends Notifier<PropertyState> {
  late final PropertyRepository _repository;

  @override
  PropertyState build() {
    _repository = ref.watch(propertyRepositoryProvider);
    return PropertyState(rooms: const [], parking: const []);
  }

  Future<int> createNewListing() async {
    final result = await _repository.createListing(
      state.propertyTypeId > 0 ? state.propertyTypeId : null,
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
    state = await _repository.loadListing(id);
  }

  Future<void> savePropertyType() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.updatePropertyType(id, state.propertyTypeId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: mapFailure(e).message,
      );
    }
  }

  Future<void> saveAddress() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.upsertAddress(id, state);
    } catch (e) {
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
      state = state.copyWith(
        errorMessage: mapFailure(e).message,
      );
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
      state = state.copyWith(
        errorMessage: mapFailure(e).message,
      );
    }
  }

  Future<void> saveValuation() async {
    final id = state.listingId;
    if (id == null) return;
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.upsertValuation(id, state);
      await _repository.upsertRunningCosts(id, state);
    } catch (e) {
      state = state.copyWith(errorMessage: mapFailure(e).message);
    }
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

  void addCustomRoom(String name, int roomTypeId) {
    final defaults = roomDefaultFeatures[roomTypeId] ?? [];
    final newRoom = Room(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      roomTypeId: roomTypeId,
      features: defaults.map((d) => RoomFeature(description: d)).toList(),
    );
    state = state.copyWith(rooms: [...state.rooms, newRoom]);
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
  }) {
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
    String? municipalAccount,
  }) {
    state = state.copyWith(
      propertyRunningCosts: state.propertyRunningCosts.copyWith(
        monthlyLevy: monthlyLevy,
        monthlyRates: monthlyRates,
        electricity: electricity,
        water: water,
        municipalAccount: municipalAccount,
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

  Future<bool> submitAndSave() async {
    final listingId = state.listingId;
    state = state.copyWith(errorMessage: null);

    if (listingId == null) {
      state = state.copyWith(errorMessage: const NetworkFailure().message);
      return false;
    }

    try {
      await _repository.upsertAddress(listingId, state);
      await _repository.upsertBuildingInfo(listingId, state);
      final syncedRooms = await _repository.upsertRooms(listingId, state.rooms);
      await _repository.upsertParking(listingId, state.parking);
      await _repository.upsertOutdoorFeatures(listingId, state.outdoorFeatures);
      await _repository.upsertValuation(listingId, state);
      await _repository.upsertRunningCosts(listingId, state);
      final syncedContacts = await _repository.upsertContacts(
        listingId,
        state.primaryContact,
        state.coContacts,
      );
      await _repository.submitListing(listingId);
      if (ref.mounted) {
        final includedPrimary = state.primaryContact.fullName.isNotEmpty;
        state = state.copyWith(
          rooms: syncedRooms,
          primaryContact: includedPrimary && syncedContacts.isNotEmpty
              ? syncedContacts.first
              : const Contact(),
          coContacts: includedPrimary
              ? (syncedContacts.length > 1 ? syncedContacts.sublist(1) : [])
              : syncedContacts,
        );
      }
      return true;
    } catch (e) {
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
      state = state.copyWith(errorMessage: mapFailure(e).message);
      rethrow;
    }
  }

  void reset() {
    state = PropertyState(
      rooms: const [],
      parking: const [],
      propertyTypeId: 0,
    );
  }
}
