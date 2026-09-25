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

  /// When the agent archived the listing; null while it is active.
  final DateTime? archivedAt;

  /// Every owner's name, primary owner first. Empty when none captured.
  final List<String> ownerNames;

  bool get isArchived => archivedAt != null;

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
    this.archivedAt,
    this.ownerNames = const [],
  });

  /// Owners for a card: "Jane", "Jane & John", or "Jane, John +1".
  String get ownersLine {
    final names = ownerNames.isNotEmpty
        ? ownerNames
        : [if ((primaryOwnerName ?? '').trim().isNotEmpty) primaryOwnerName!];
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} & ${names[1]}';
    return '${names[0]}, ${names[1]} +${names.length - 2}';
  }

  /// Lower-cased text the archive search matches against: address, every
  /// owner, reference and P24 numbers.
  String get searchText => [
    addressLine,
    ...ownerNames,
    primaryOwnerName ?? '',
    referenceNumber,
    p24Ref ?? '',
  ].join(' ').toLowerCase();

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
