class AddParkingRequest {
  final int parkingTypeId;
  final int quantity;

  const AddParkingRequest({required this.parkingTypeId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'parkingTypeId': parkingTypeId,
        'quantity': quantity,
      };
}

class UpdateParkingRequest {
  final int quantity;

  const UpdateParkingRequest({required this.quantity});

  Map<String, dynamic> toJson() => {'quantity': quantity};
}

class ParkingDto {
  final int id;
  final int listingId;
  final int parkingTypeId;
  final int quantity;
  final String parkingTypeDescription;

  const ParkingDto({
    required this.id,
    required this.listingId,
    required this.parkingTypeId,
    required this.quantity,
    required this.parkingTypeDescription,
  });

  factory ParkingDto.fromJson(Map<String, dynamic> json) {
    return ParkingDto(
      id: json['id'] as int,
      listingId: json['listingId'] as int,
      parkingTypeId: json['parkingTypeId'] as int,
      quantity: json['quantity'] as int,
      parkingTypeDescription: json['parkingTypeDescription'] as String? ?? '',
    );
  }
}
