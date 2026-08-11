import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../services/auth_api_service.dart';
import '../services/lookup_api_service.dart';
import '../services/listing_api_service.dart';
import '../services/room_api_service.dart';
import '../services/contact_api_service.dart';
import '../services/parking_api_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApiService(client);
});

final lookupApiServiceProvider = Provider<LookupApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return LookupApiService(client);
});

final listingApiServiceProvider = Provider<ListingApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ListingApiService(client);
});

final roomApiServiceProvider = Provider<RoomApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return RoomApiService(client);
});

final contactApiServiceProvider = Provider<ContactApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ContactApiService(client);
});

final parkingApiServiceProvider = Provider<ParkingApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ParkingApiService(client);
});
