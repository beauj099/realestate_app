import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/lookup_dtos.dart';

class LookupApiService {
  final ApiClient _client;

  LookupApiService(this._client);

  Future<List<PropertyTypeDto>> getPropertyTypes() async {
    final response = await _client.get(ApiEndpoints.propertyTypes);
    return (response.data as List)
        .map((e) => PropertyTypeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RoomTypeDto>> getRoomTypes() async {
    final response = await _client.get(ApiEndpoints.roomTypes);
    return (response.data as List)
        .map((e) => RoomTypeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeatureDto>> getFeatures() async {
    final response = await _client.get(ApiEndpoints.features);
    return (response.data as List)
        .map((e) => FeatureDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConditionCategoryDto>> getConditionCategories() async {
    final response = await _client.get(ApiEndpoints.conditionCategories);
    return (response.data as List)
        .map((e) => ConditionCategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParkingTypeDto>> getParkingTypes() async {
    final response = await _client.get(ApiEndpoints.parkingTypes);
    return (response.data as List)
        .map((e) => ParkingTypeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FacingDto>> getFacing() async {
    final response = await _client.get(ApiEndpoints.facing);
    return (response.data as List)
        .map((e) => FacingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ZoningDto>> getZoning() async {
    final response = await _client.get(ApiEndpoints.zoning);
    return (response.data as List)
        .map((e) => ZoningDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
