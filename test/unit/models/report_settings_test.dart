import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/auth/data/models/agent_profile.dart';
import 'package:realworth/features/property_overview/data/models/enums/room_category.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';
import 'package:realworth/features/property_overview/data/models/room_score.dart';
import 'package:realworth/features/report_settings/data/models/report_settings.dart';

Room _room(String name, {double? score}) => Room(
  id: name,
  name: name,
  roomTypeId: RoomCategoryExtension.roomTypeIdForType(name),
  score: score,
);

void main() {
  tearDown(() => RoomScore.weights = RoomWeights.defaults);

  test('report settings survive a round trip, and missing ones default', () {
    final settings = const ReportSettings().copyWith(
      calculator: const CalculatorDefaults().copyWith(
        commissionEarlyPercent: 4.5,
        interestRatePercent: 11.25,
      ),
      roomWeights: RoomWeights.defaults.withWeight(RoomWeightClass.kitchen, 4),
    );
    final back = ReportSettings.fromJson(settings.toJson());
    expect(back.calculator.commissionEarlyPercent, 4.5);
    expect(back.calculator.interestRatePercent, 11.25);
    expect(back.calculator.bondTermYears, 20);
    expect(back.roomWeights.of(RoomWeightClass.kitchen), 4);
    expect(back.roomWeights.of(RoomWeightClass.bathroom), 2);

    expect(ReportSettings.fromJson(null).calculator.commissionLatePercent, 6);
  });

  test("the agent's room weights change the suggested house score", () {
    final rooms = [
      _room('Kitchen', score: 9),
      _room('Storeroom / Workshop', score: 3),
    ];
    final byDefault = RoomScore.suggestedHousePercent(rooms)!;

    RoomScore.weights = RoomWeights.defaults
        .withWeight(RoomWeightClass.kitchen, 1)
        .withWeight(RoomWeightClass.storage, 1);
    final evenly = RoomScore.suggestedHousePercent(rooms)!;

    expect(byDefault, greaterThan(evenly));
    expect(evenly, 60);
  });

  test('default weights are the ones the app used before', () {
    expect(RoomScore.weightFor(_room('Kitchen')), 3);
    expect(RoomScore.weightFor(_room('Main Bedroom / Master Suite')), 2.5);
    expect(RoomScore.weightFor(_room('Scullery')), 1);
    expect(RoomScore.weightFor(_room('Storeroom / Workshop')), 0.5);
  });

  test("an agent's office falls back to the agency's field by field", () {
    const agency = OfficeDetails(
      name: 'KW Dynamic',
      address: '51 Reitz St, Audas Estate, Somerset West, 7130',
      phone: '+27 21 913 8391',
    );
    const own = OfficeDetails(phone: '021 000 0000');
    final office = own.orDefaults(agency);
    expect(office.name, 'KW Dynamic');
    expect(office.phone, '021 000 0000');
  });

  test('reads the report-pack fields from the API', () {
    final profile = AgentProfile.fromApi({
      'displayName': 'Collin Bruwer',
      'email': 'collin@example.com',
      'licenceNumber': '202635070730000',
      'ppraNumber': '1208568',
      'jobTitle': 'Property Practitioner Specialist',
      'qualifications': ['NQF4', 'PDE4'],
      'photoUrl': 'https://example.com/p.jpg',
      'office': {'name': 'KW Dynamic', 'phone': null},
      'brochurePages': null,
      'reportSettings': {
        'calculator': {'interestRatePercent': 11},
      },
    });
    expect(profile.firstName, 'Collin');
    expect(profile.ppraNumber, '1208568');
    expect(profile.qualifications, ['NQF4', 'PDE4']);
    expect(profile.office.name, 'KW Dynamic');
    expect(profile.office.phone, '');
    expect(profile.brochurePages, isNull);
    expect(profile.reportSettings.calculator.interestRatePercent, 11);
    expect(AgentProfile.initialsOf(profile.fullName), 'CB');
  });
}
