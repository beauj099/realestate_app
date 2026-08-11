import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers/api_providers.dart';
import '../actions/address_actions.dart';
import '../actions/building_info_actions.dart';
import '../actions/contacts_actions.dart';
import '../actions/listing_valuation_actions.dart';
import '../actions/property_features_actions.dart';
import '../actions/property_type_actions.dart';
import '../actions/room_details_actions.dart';
import '../actions/wizard_step_actions.dart';
import '../data/models/contact.dart';
import '../data/models/property_state.dart';
import '../data/repositories/property_repository.dart';
import '../data/repositories/property_repository_impl.dart';

final propertyRepositoryProvider = Provider.autoDispose<IPropertyRepository>((
  ref,
) {
  final listingApi = ref.watch(listingApiServiceProvider);
  final roomApi = ref.watch(roomApiServiceProvider);
  final contactApi = ref.watch(contactApiServiceProvider);
  final parkingApi = ref.watch(parkingApiServiceProvider);
  return PropertyRepositoryImpl(
    listingApi: listingApi,
    roomApi: roomApi,
    contactApi: contactApi,
    parkingApi: parkingApi,
  );
});

final propertyViewModelProvider =
    NotifierProvider.autoDispose<PropertyViewModel, PropertyState>(() {
      return PropertyViewModel();
    });

class PropertyViewModel extends Notifier<PropertyState> {
  late final IPropertyRepository _repository;

  @override
  PropertyState build() {
    _repository = ref.watch(propertyRepositoryProvider);
    return PropertyState(rooms: const [], parking: const []);
  }

  Future<void> startWizard() async {
    final listingId = await _repository.createListing(state.propertyTypeId);
    state = state.copyWith(listingId: listingId, referenceNumber: '');
  }

  void setStep(int step) {
    state = state.withStep(step);
  }

  Future<void> nextStep() async {
    final currentStep = state.currentStep;

    state = state.copyWith(errorMessage: null);
    try {
      if (currentStep == 1 && state.listingId == null) {
        await startWizard();
      }

      final listingId = state.listingId;
      if (listingId != null) {
        switch (currentStep) {
          case 2:
            await _repository.upsertAddress(listingId, state);
            break;
          case 3:
            await _repository.upsertBuildingInfo(listingId, state);
            break;
          case 4:
            await _repository.upsertRooms(listingId, state.rooms);
            await _repository.upsertParking(listingId, state.parking);
            break;
          case 5:
            await _repository.upsertValuation(listingId, state);
            await _repository.upsertRunningCosts(listingId, state);
            break;
          case 6:
            await _repository.upsertContacts(
              listingId,
              state.primaryContact,
              state.coContacts,
            );
            break;
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save: $e');
      return;
    }

    state = state.withNextStep();
  }

  void prevStep() {
    state = state.withPrevStep();
  }

  void selectPropertyType(int id) {
    state = state.withPropertyTypeId(id);
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
    state = state.withAddress(
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

  void updateIdentifiers({String? estateName, String? erfNumber}) {
    state = state.withIdentifiers(estateName: estateName, erfNumber: erfNumber);
  }

  void updateTechnicalSpecs({
    String? erfSize,
    String? floorArea,
    String? constructionYear,
  }) {
    state = state.withTechnicalSpecs(
      erfSize: erfSize,
      floorArea: floorArea,
      constructionYear: constructionYear,
    );
  }

  void selectFacingId(int? id) {
    state = state.withFacingId(id);
  }

  void selectZoningId(int? id) {
    state = state.withZoningId(id);
  }

  void addCustomRoom(String name, int roomTypeId) {
    state = state.withAddedRoom(name, roomTypeId);
  }

  void removeRoom(String roomId) {
    state = state.withRemovedRoom(roomId);
  }

  void addParking(int parkingTypeId) {
    state = state.withAddedParking(parkingTypeId);
  }

  void removeParking(int parkingTypeId) {
    state = state.withRemovedParking(parkingTypeId);
  }

  void selectRoomForEditing(String? roomId) {
    state = state.withSelectedRoom(roomId);
  }

  void updateRoomDetails({
    required String roomId,
    int? conditionRating,
    List<String>? features,
    List<int>? featureIds,
    String? notes,
    String? photoUrl,
  }) {
    state = state.withUpdatedRoomDetails(
      roomId: roomId,
      conditionRating: conditionRating,
      features: features,
      featureIds: featureIds,
      notes: notes,
      photoUrl: photoUrl,
    );
  }

  void renameRoom(String roomId, String newName) {
    state = state.withRenamedRoom(roomId, newName);
  }

  void addFeatureToRoom(String roomId, String feature) {
    state = state.withAddedFeature(roomId, feature);
  }

  void removeFeatureFromRoom(String roomId, String feature) {
    state = state.withRemovedFeature(roomId, feature);
  }

  void updateValuation({
    String? ownersNetPrice,
    String? agentValuation,
    String? commissionPercent,
  }) {
    state = state.withValuation(
      ownersNetPrice: ownersNetPrice,
      agentValuation: agentValuation,
      commissionPercent: commissionPercent,
    );
  }

  void updateRunningCosts({
    String? monthlyLevy,
    String? monthlyRates,
    String? electricity,
    String? water,
  }) {
    state = state.withRunningCosts(
      monthlyLevy: monthlyLevy,
      monthlyRates: monthlyRates,
      electricity: electricity,
      water: water,
    );
  }

  void updatePrimaryContact(Contact contact) {
    state = state.withPrimaryContact(contact);
  }

  void addCoContact() {
    state = state.withAddedCoContact();
  }

  void updateCoContact(int index, Contact contact) {
    state = state.withUpdatedCoContact(index, contact);
  }

  void removeCoContact(String id) {
    state = state.withRemovedCoContact(id);
  }

  Future<void> saveDraft() async {
    await _repository.savePropertyDraft(state);
  }

  Future<bool> submitAndSave() async {
    final listingId = state.listingId;
    state = state.copyWith(errorMessage: null);

    if (listingId == null) {
      state = state.copyWith(
        errorMessage: 'Listing was never created on the server. '
            'Please check your connection and start again.',
      );
      return false;
    }

    try {
      await _repository.upsertAddress(listingId, state);
      await _repository.upsertBuildingInfo(listingId, state);
      await _repository.upsertRooms(listingId, state.rooms);
      await _repository.upsertParking(listingId, state.parking);
      await _repository.upsertValuation(listingId, state);
      await _repository.upsertRunningCosts(listingId, state);
      await _repository.upsertContacts(
        listingId,
        state.primaryContact,
        state.coContacts,
      );
      await _repository.submitListing(listingId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to submit: $e');
      await _repository.savePropertyDraft(state);
      return false;
    }
  }

  void reset() {
    state = PropertyState(rooms: const [], parking: const []);
  }
}
