import '../api_client.dart';
import '../api_endpoints.dart';
import '../dto/contact_dtos.dart';

class ContactApiService {
  final ApiClient _client;

  ContactApiService(this._client);

  Future<List<ContactDto>> getContacts(int listingId) async {
    final response = await _client.get(ApiEndpoints.listingContacts(listingId));
    return (response.data as List)
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContactDto> addContact(int listingId, AddContactRequest request) async {
    final response = await _client.post(
        ApiEndpoints.listingContacts(listingId),
        data: request.toJson());
    return ContactDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ContactDto?> updateContact(
      int listingId, int contactId, UpdateContactRequest request) async {
    final response = await _client.put(
        ApiEndpoints.listingSingleContact(listingId, contactId),
        data: request.toJson());
    return ContactDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteContact(int listingId, int contactId) async {
    await _client.delete(
        ApiEndpoints.listingSingleContact(listingId, contactId));
  }
}
