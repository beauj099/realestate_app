import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/enums/room_category.dart';
import 'package:realworth/features/property_overview/data/models/property_state.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';
import 'package:realworth/features/property_overview/data/models/room_score.dart';

Room _room(String name, {double? score, int? conditionRating}) => Room(
  id: name,
  name: name,
  roomTypeId: RoomCategoryExtension.roomTypeIdForType(name),
  score: score,
  conditionRating: conditionRating,
);

void main() {
  group('room weights', () {
    test('important rooms count more than minor ones', () {
      expect(
        RoomScore.weightFor(_room('Kitchen')),
        greaterThan(RoomScore.weightFor(_room('Scullery'))),
      );
      expect(
        RoomScore.weightFor(_room('Main Bedroom / Master Suite')),
        greaterThan(RoomScore.weightFor(_room('Bedroom'))),
      );
      expect(
        RoomScore.weightFor(_room('Full Bathroom')),
        greaterThan(RoomScore.weightFor(_room('Storeroom / Workshop'))),
      );
    });

    test('renamed rooms fall back to their category', () {
      final renamed = Room(id: 'x', name: 'Bedroom1', roomTypeId: 1);
      expect(RoomScore.weightFor(renamed), 1.5);
    });
  });

  group('suggested house score', () {
    test('good main rooms outweigh a poor storeroom', () {
      final rooms = [
        _room('Kitchen', score: 9),
        _room('Full Bathroom', score: 9),
        _room('Storeroom / Workshop', score: 2),
      ];
      final plainAverage = (9 + 9 + 2) / 3 * 10; // ~66.7%
      final suggested = RoomScore.suggestedHousePercent(rooms)!;
      expect(suggested, greaterThan(plainAverage));
      // (3×9 + 2×9 + 0.5×2) / 5.5 = 8.36 → 83.6%.
      expect(suggested, closeTo(83.6, 0.05));
    });

    test('is null until a room is scored', () {
      expect(RoomScore.suggestedHousePercent([_room('Kitchen')]), isNull);
    });

    test('percentages are shown whole', () {
      expect(RoomScore.percent(84.1), '84%');
      expect(RoomScore.percent(70), '70%');
    });
  });

  group('house score on the listing', () {
    final rooms = [_room('Kitchen', score: 8)];

    test('follows the suggestion until the agent sets one', () {
      final s = PropertyState(rooms: rooms, savedHouseScore: 50);
      expect(s.houseScore, 80);
    });

    test("the agent's own score wins once set", () {
      final s = PropertyState(
        rooms: rooms,
        savedHouseScore: 65,
        houseScoreIsManual: true,
      );
      expect(s.houseScore, 65);
      expect(s.suggestedHouseScore, 80);
    });
  });

  group('property features completeness', () {
    test('needs every room rated or scored', () {
      final some = PropertyState(
        rooms: [_room('Kitchen', score: 7), _room('Lounge')],
      );
      expect(some.isFeaturesComplete, isFalse);
      expect(some.ratedRoomCount, 1);

      final all = PropertyState(
        rooms: [
          _room('Kitchen', score: 7),
          _room('Lounge', conditionRating: 4),
        ],
      );
      expect(all.isFeaturesComplete, isTrue);
    });

    test('is not complete without rooms', () {
      expect(PropertyState(rooms: const []).isFeaturesComplete, isFalse);
    });
  });

  test('rooms hold several photos, the first being the cover', () {
    final room = Room(
      id: '1',
      name: 'Lounge',
      photos: const [
        RoomPhoto(id: 1, path: '/uploads/a.jpg'),
        RoomPhoto(path: '/local/b.jpg'),
      ],
    );
    expect(room.photoUrl, '/uploads/a.jpg');
    expect(room.photos.last.isUploaded, isFalse);
    expect(Room.maxPhotos, 20);
  });
}
