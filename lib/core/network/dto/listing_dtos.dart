import 'address_dtos.dart';
import 'building_info_dtos.dart';
import 'valuation_dtos.dart';
import 'room_dtos.dart';
import 'parking_dtos.dart';
import 'contact_dtos.dart';

class CreateListingRequest {
  final int propertyTypeId;
  final String? p24Ref;

  const CreateListingRequest({required this.propertyTypeId, this.p24Ref});

  Map<String, dynamic> toJson() => {
        'propertyTypeId': propertyTypeId,
        if (p24Ref != null) 'p24Ref': p24Ref,
      };
}

class UpdateListingRequest {
  final String? status;
  final String? p24Ref;
  final int? propertyTypeId;

  const UpdateListingRequest({this.status, this.p24Ref, this.propertyTypeId});

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status,
        if (p24Ref != null) 'p24Ref': p24Ref,
        if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
      };
}

class ListingSummaryDto {
  final int id;
  final String referenceNumber;
  final String? p24Ref;
  final int propertyTypeId;
  final int? listingValuationId;
  final DateTime? listDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ListingSummaryDto({
    required this.id,
    required this.referenceNumber,
    this.p24Ref,
    required this.propertyTypeId,
    this.listingValuationId,
    this.listDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingSummaryDto.fromJson(Map<String, dynamic> json) {
    return ListingSummaryDto(
      id: json['id'] as int,
      referenceNumber: json['referenceNumber'] as String,
      p24Ref: json['p24Ref'] as String?,
      propertyTypeId: json['propertyTypeId'] as int,
      listingValuationId: json['listingValuationId'] as int?,
      listDate: json['listDate'] != null
          ? DateTime.parse(json['listDate'] as String)
          : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ListingResponse {
  final int id;
  final String referenceNumber;
  final String? p24Ref;
  final int propertyTypeId;
  final int? listingValuationId;
  final DateTime? listDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ListingAddressDto? address;
  final BuildingInfoDto? buildingInfo;
  final ValuationDto? valuation;
  final RunningCostsDto? runningCosts;
  final List<RoomDto> rooms;
  final List<ParkingDto> parking;
  final List<ContactDto> contacts;

  const ListingResponse({
    required this.id,
    required this.referenceNumber,
    this.p24Ref,
    required this.propertyTypeId,
    this.listingValuationId,
    this.listDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.buildingInfo,
    this.valuation,
    this.runningCosts,
    this.rooms = const [],
    this.parking = const [],
    this.contacts = const [],
  });

  factory ListingResponse.fromJson(Map<String, dynamic> json) {
    return ListingResponse(
      id: json['id'] as int,
      referenceNumber: json['referenceNumber'] as String,
      p24Ref: json['p24Ref'] as String?,
      propertyTypeId: json['propertyTypeId'] as int,
      listingValuationId: json['listingValuationId'] as int?,
      listDate: json['listDate'] != null
          ? DateTime.parse(json['listDate'] as String)
          : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      address: json['address'] != null
          ? ListingAddressDto.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      buildingInfo: json['buildingInfo'] != null
          ? BuildingInfoDto.fromJson(json['buildingInfo'] as Map<String, dynamic>)
          : null,
      valuation: json['valuation'] != null
          ? ValuationDto.fromJson(json['valuation'] as Map<String, dynamic>)
          : null,
      runningCosts: json['runningCosts'] != null
          ? RunningCostsDto.fromJson(json['runningCosts'] as Map<String, dynamic>)
          : null,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => RoomDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      parking: (json['parking'] as List<dynamic>?)
              ?.map((e) => ParkingDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
