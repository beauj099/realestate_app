import '../data/models/property_state.dart';

extension PropertyTypeActions on PropertyState {
  PropertyState withPropertyTypeId(int id) =>
      copyWith(propertyTypeId: id);
}
