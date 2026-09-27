import '../../property_overview/data/models/enums/room_category.dart';
import '../../property_overview/data/models/property_state.dart';

/// The cover's "Property portfolio": what the agent captured about the home.
List<String> packPortfolio(PropertyState s) {
  int count(RoomCategory c) => s.rooms
      .where(
        (r) => RoomCategoryExtension.categoryForRoomTypeId(r.roomTypeId) == c,
      )
      .length;
  bool named(String word) =>
      s.rooms.any((r) => r.name.toLowerCase().contains(word));
  String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

  final bedrooms = count(RoomCategory.bedroom);
  final bathrooms = count(RoomCategory.bathroom);
  final ensuites = s.rooms
      .where(
        (r) =>
            r.name.toLowerCase().contains('en-suite') ||
            r.name.toLowerCase().contains('ensuite'),
      )
      .length;
  final living = count(RoomCategory.livingSpaces);
  final parking = s.parking.fold<int>(0, (n, p) => n + p.quantity);
  final floor = double.tryParse(s.floorArea.replaceAll(',', '.'));
  final year = int.tryParse(s.constructionYear.trim());

  return [
    if (floor != null && floor > 0) 'Floor area: ${floor.round()} m²',
    if (year != null && year > 1800) 'Built in $year',
    if (bedrooms > 0 || bathrooms > 0)
      [
        if (bedrooms > 0) plural(bedrooms, 'bedroom', 'bedrooms'),
        if (bathrooms > 0)
          '${plural(bathrooms, 'bathroom', 'bathrooms')}${ensuites > 0 ? ' ($ensuites en-suite)' : ''}',
      ].join(', '),
    if (living > 0) plural(living, 'living area', 'living areas'),
    if (named('kitchen'))
      'Kitchen${named('pantry') ? ' + pantry' : ''}${named('scullery') ? ' + scullery' : ''}',
    if (named('study') || named('office')) 'Study / office',
    if (named('flatlet') || named('granny') || named('cottage')) 'Flatlet',
    if (parking > 0) plural(parking, 'parking bay', 'parking bays'),
    if (s.outdoorFeatures.isNotEmpty) s.outdoorFeatures.take(8).join(', '),
  ];
}

/// The owners as the pack names them: "Francois du Toit & Ree du Toit", and
/// their first names for the letter: "Francois & Ree". Agents can change both.
(String preparedFor, String greeting) packOwners(PropertyState s) {
  final people = [s.primaryContact, ...s.coContacts]
      .map(
        (c) => c.companyName.trim().isNotEmpty && c.fullName.trim().isEmpty
            ? c.companyName.trim()
            : c.fullName.trim(),
      )
      .where((n) => n.isNotEmpty)
      .toList();
  final firstNames = people.map((n) => n.split(RegExp(r'\s+')).first).toList();
  return (people.join(' & '), firstNames.join(' & '));
}
