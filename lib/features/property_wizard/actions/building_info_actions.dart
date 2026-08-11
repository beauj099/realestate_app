import '../data/models/property_state.dart';

extension BuildingInfoActions on PropertyState {
  PropertyState withTechnicalSpecs({
    String? erfSize,
    String? floorArea,
    String? constructionYear,
  }) {
    return copyWith(
      erfSize: erfSize ?? this.erfSize,
      floorArea: floorArea ?? this.floorArea,
      constructionYear: constructionYear ?? this.constructionYear,
    );
  }

  PropertyState withFacingId(int? id) =>
      copyWith(facingId: id);

  PropertyState withZoningId(int? id) =>
      copyWith(zoningId: id);
}
