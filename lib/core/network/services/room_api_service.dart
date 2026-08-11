import 'package:dio/dio.dart';

import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/room_dtos.dart';

class RoomApiService {
  final ApiClient _client;

  RoomApiService(this._client);

  Future<List<RoomDto>> getRooms(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingRooms(listingId));
    return (response.data as List)
        .map((e) => RoomDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RoomDto> createRoom(int listingId, CreateRoomRequest request) async {
    final response = await _client.post(
      ApiEndpoints.listingRooms(listingId),
      data: request.toJson(),
    );
    return RoomDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoomDto?> updateRoom(
    int listingId,
    int roomId,
    UpdateRoomRequest request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.listingRoom(listingId, roomId),
      data: request.toJson(),
    );
    return RoomDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRoom(int listingId, int roomId) async {
    await _client.delete(ApiEndpoints.listingRoom(listingId, roomId));
  }

  Future<RoomConditionDto> upsertCondition(
    int listingId,
    int roomId,
    UpsertRoomConditionRequest request,
  ) async {
    final response = await _client.put(
      ApiEndpoints.listingRoomCondition(listingId, roomId),
      data: request.toJson(),
    );
    return RoomConditionDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> linkFeature(int listingId, int roomId, int featureId) async {
    await _client.post(
      ApiEndpoints.listingRoomFeatures(listingId, roomId),
      data: LinkFeatureRequest(featureId: featureId).toJson(),
    );
  }

  Future<void> unlinkFeature(int listingId, int roomId, int featureId) async {
    await _client.delete(
      ApiEndpoints.listingRoomFeature(listingId, roomId, featureId),
    );
  }

  Future<CustomFeatureDto> addCustomFeature(
    int listingId,
    int roomId,
    String description,
  ) async {
    final response = await _client.post(
      ApiEndpoints.listingRoomCustomFeatures(listingId, roomId),
      data: AddCustomFeatureRequest(description: description).toJson(),
    );
    return CustomFeatureDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCustomFeature(
    int listingId,
    int roomId,
    int customFeatureId,
  ) async {
    await _client.delete(
      ApiEndpoints.listingRoomCustomFeature(listingId, roomId, customFeatureId),
    );
  }

  Future<void> uploadPhoto(int listingId, int roomId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'room_photo.jpg',
      ),
    });
    await _client.post(
      ApiEndpoints.listingRoomPhoto(listingId, roomId),
      data: formData,
    );
  }
}
