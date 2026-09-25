import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../services/agency_api_service.dart';
import '../services/agent_api_service.dart';
import '../services/auth_api_service.dart';
import '../services/lookup_api_service.dart';

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

final agentApiServiceProvider = Provider<AgentApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AgentApiService(client);
});

final agencyApiServiceProvider = Provider<AgencyApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AgencyApiService(client);
});
