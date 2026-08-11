import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/parking_dtos.dart';

class ParkingApiService {
  final ApiClient _client;

  ParkingApiService(this._client);

  Future<List<ParkingDto>> getParking(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingParking(listingId));
    return (response.data as List)
        .map((e) => ParkingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParkingDto> addParking(int listingId, AddParkingRequest request) async {
    final response = await _client.post(
        ApiEndpoints.listingParking(listingId),
        data: request.toJson());
    return ParkingDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ParkingDto?> updateParking(
      int listingId, int parkingId, UpdateParkingRequest request) async {
    final response = await _client.put(
        ApiEndpoints.listingSingleParking(listingId, parkingId),
        data: request.toJson());
    return ParkingDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteParking(int listingId, int parkingId) async {
    await _client.delete(
        ApiEndpoints.listingSingleParking(listingId, parkingId));
  }
}
