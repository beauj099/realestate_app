import '../data/models/property_state.dart';

extension RoomDetailsActions on PropertyState {
  PropertyState withSelectedRoom(String? roomId) =>
      copyWith(selectedRoomId: roomId);

  PropertyState withUpdatedRoomDetails({
    required String roomId,
    int? conditionRating,
    List<String>? features,
    List<int>? featureIds,
    String? notes,
    String? photoUrl,
  }) {
    final updatedRooms = rooms.map((room) {
      if (room.id == roomId) {
        return room.copyWith(
          conditionRating: conditionRating ?? room.conditionRating,
          features: features ?? room.features,
          featureIds: featureIds ?? room.featureIds,
          notes: notes ?? room.notes,
          photoUrl: photoUrl ?? room.photoUrl,
        );
      }
      return room;
    }).toList();
    return copyWith(rooms: updatedRooms);
  }

  PropertyState withRenamedRoom(String roomId, String newName) {
    final updatedRooms = rooms.map((room) {
      if (room.id == roomId) {
        return room.copyWith(name: newName);
      }
      return room;
    }).toList();
    return copyWith(rooms: updatedRooms);
  }

  PropertyState withAddedFeature(String roomId, String feature) {
    final updatedRooms = rooms.map((room) {
      if (room.id == roomId) {
        final currentFeatures = List<String>.from(room.features);
        if (!currentFeatures.contains(feature)) {
          currentFeatures.add(feature);
        }
        return room.copyWith(features: currentFeatures);
      }
      return room;
    }).toList();
    return copyWith(rooms: updatedRooms);
  }

  PropertyState withRemovedFeature(String roomId, String feature) {
    final updatedRooms = rooms.map((room) {
      if (room.id == roomId) {
        final currentFeatures = List<String>.from(room.features);
        currentFeatures.remove(feature);
        return room.copyWith(features: currentFeatures);
      }
      return room;
    }).toList();
    return copyWith(rooms: updatedRooms);
  }
}
