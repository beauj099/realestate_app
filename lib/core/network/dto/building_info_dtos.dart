class UpsertBuildingInfoRequest {
  final num? erfSize;
  final num? floorArea;
  final int? constructionYear;
  final int? facingId;
  final int? zoningId;

  const UpsertBuildingInfoRequest({
    this.erfSize,
    this.floorArea,
    this.constructionYear,
    this.facingId,
    this.zoningId,
  });

  Map<String, dynamic> toJson() => {
        if (erfSize != null) 'erfSize': erfSize,
        if (floorArea != null) 'floorArea': floorArea,
        if (constructionYear != null) 'constructionYear': constructionYear,
        if (facingId != null) 'facingId': facingId,
        if (zoningId != null) 'zoningId': zoningId,
      };
}

class BuildingInfoDto {
  final int id;
  final int listingId;
  final num? erfSize;
  final num? floorArea;
  final int? constructionYear;
  final int? facingId;
  final int? zoningId;

  const BuildingInfoDto({
    required this.id,
    required this.listingId,
    this.erfSize,
    this.floorArea,
    this.constructionYear,
    this.facingId,
    this.zoningId,
  });

  factory BuildingInfoDto.fromJson(Map<String, dynamic> json) {
    return BuildingInfoDto(
      id: json['id'] as int,
      listingId: json['listingId'] as int,
      erfSize: json['erfSize'] as num?,
      floorArea: json['floorArea'] as num?,
      constructionYear: json['constructionYear'] as int?,
      facingId: json['facingId'] as int?,
      zoningId: json['zoningId'] as int?,
    );
  }
}
