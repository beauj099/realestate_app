class ListingParking {
  final String id;
  final int parkingTypeId;
  final int quantity;

  const ListingParking({
    this.id = '',
    this.parkingTypeId = 1,
    this.quantity = 1,
  });

  ListingParking copyWith({
    String? id,
    int? parkingTypeId,
    int? quantity,
  }) {
    return ListingParking(
      id: id ?? this.id,
      parkingTypeId: parkingTypeId ?? this.parkingTypeId,
      quantity: quantity ?? this.quantity,
    );
  }
}
