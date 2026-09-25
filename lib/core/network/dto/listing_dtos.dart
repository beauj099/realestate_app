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

  /// Human-readable card fields served inline by `GET /api/listings`
  /// (address, first owner, primary photo, room count). All nullable/empty
  /// when the deployed API predates them — cards degrade to placeholders.
  final String? streetNumber;
  final String? street;
  final String? suburb;
  final String? city;
  final String? primaryOwnerName;
  final String? primaryPhotoUrl;
  final int roomCount;

  /// House score saved on the listing, as a percentage; null until set.
  final double? houseScore;

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
    this.streetNumber,
    this.street,
    this.suburb,
    this.city,
    this.primaryOwnerName,
    this.primaryPhotoUrl,
    this.roomCount = 0,
    this.houseScore,
  });

  /// "12 Main Road, Suburb, City" — empty when no address captured yet.
  String get addressLine {
    final streetLine = [
      streetNumber?.trim() ?? '',
      street?.trim() ?? '',
    ].where((p) => p.isNotEmpty).join(' ');
    return [
      streetLine,
      suburb?.trim() ?? '',
      city?.trim() ?? '',
    ].where((p) => p.isNotEmpty).join(', ');
  }
}
