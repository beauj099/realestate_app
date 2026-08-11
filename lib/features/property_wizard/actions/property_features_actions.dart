import '../data/models/listing_parking.dart';
import '../data/models/property_state.dart';
import '../data/models/room.dart';

extension PropertyFeaturesActions on PropertyState {
  PropertyState withAddedRoom(String name, int roomTypeId) {
    final newRoom = Room(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      roomTypeId: roomTypeId,
    );
    return copyWith(rooms: [...rooms, newRoom]);
  }

  PropertyState withRemovedRoom(String roomId) {
    return copyWith(rooms: rooms.where((r) => r.id != roomId).toList());
  }

  PropertyState withAddedParking(int parkingTypeId) {
    final current = List<ListingParking>.from(parking);
    final existingIdx = current.indexWhere((p) => p.parkingTypeId == parkingTypeId);
    if (existingIdx >= 0) {
      current[existingIdx] = current[existingIdx].copyWith(
        quantity: current[existingIdx].quantity + 1,
      );
    } else {
      current.add(ListingParking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parkingTypeId: parkingTypeId,
        quantity: 1,
      ));
    }
    return copyWith(parking: current);
  }

  PropertyState withRemovedParking(int parkingTypeId) {
    final current = List<ListingParking>.from(parking);
    current.removeWhere((p) => p.parkingTypeId == parkingTypeId);
    return copyWith(parking: current);
  }
}
