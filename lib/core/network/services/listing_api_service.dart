import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/listing_dtos.dart';
import '../dto/address_dtos.dart';
import '../dto/building_info_dtos.dart';
import '../dto/valuation_dtos.dart';

class ListingApiService {
  final ApiClient _client;

  ListingApiService(this._client);

  Future<ListingResponse> create(CreateListingRequest request) async {
    final response =
        await _client.post(ApiEndpoints.listings, data: request.toJson());
    return ListingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ListingSummaryDto>> getAll({
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();

    final response =
        await _client.get(ApiEndpoints.listings, queryParameters: params.isNotEmpty ? params : null);
    return (response.data as List)
        .map((e) => ListingSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListingResponse> getById(int id) async {
    final response = await _client.get(ApiEndpoints.listing(id));
    return ListingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ListingResponse> update(int id, UpdateListingRequest request) async {
    final response =
        await _client.put(ApiEndpoints.listing(id), data: request.toJson());
    return ListingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _client.delete(ApiEndpoints.listing(id));
  }

  Future<ListingResponse> submit(int id) async {
    final response = await _client.put(ApiEndpoints.listingSubmit(id));
    return ListingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Address
  Future<ListingAddressDto?> getAddress(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingAddress(listingId));
    if (response.statusCode == 404) return null;
    return ListingAddressDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ListingAddressDto> upsertAddress(
      int listingId, UpsertAddressRequest request) async {
    final response = await _client.put(ApiEndpoints.listingAddress(listingId),
        data: request.toJson());
    return ListingAddressDto.fromJson(response.data as Map<String, dynamic>);
  }

  // Building Info
  Future<BuildingInfoDto?> getBuildingInfo(int listingId) async {
    final response =
        await _client.get(ApiEndpoints.listingBuildingInfo(listingId));
    if (response.statusCode == 404) return null;
    return BuildingInfoDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BuildingInfoDto> upsertBuildingInfo(
      int listingId, UpsertBuildingInfoRequest request) async {
    final response = await _client.put(
        ApiEndpoints.listingBuildingInfo(listingId),
        data: request.toJson());
    return BuildingInfoDto.fromJson(response.data as Map<String, dynamic>);
  }

  // Valuation
  Future<ValuationDto?> getValuation(int listingId) async {
    final response =
        await _client.get(ApiEndpoints.listingValuation(listingId));
    if (response.statusCode == 404) return null;
    return ValuationDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ValuationDto> upsertValuation(
      int listingId, UpsertValuationRequest request) async {
    final response = await _client.put(
        ApiEndpoints.listingValuation(listingId),
        data: request.toJson());
    return ValuationDto.fromJson(response.data as Map<String, dynamic>);
  }

  // Running Costs
  Future<RunningCostsDto?> getRunningCosts(int listingId) async {
    final response =
        await _client.get(ApiEndpoints.listingRunningCosts(listingId));
    if (response.statusCode == 404) return null;
    return RunningCostsDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RunningCostsDto> upsertRunningCosts(
      int listingId, UpsertRunningCostsRequest request) async {
    final response = await _client.put(
        ApiEndpoints.listingRunningCosts(listingId),
        data: request.toJson());
    return RunningCostsDto.fromJson(response.data as Map<String, dynamic>);
  }
}
