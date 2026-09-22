import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/property_overview/data/models/room.dart';

void main() {
  group('Room', () {
    test('constructor sets default values', () {
      final room = Room(id: '1', name: 'Bedroom');

      expect(room.id, '1');
      expect(room.name, 'Bedroom');
      expect(room.roomTypeId, 1);
      expect(room.features, isEmpty);
      expect(room.notes, '');
      expect(room.conditionRating, isNull);
    });

    test('copyWith() overrides specified fields', () {
      final room = Room(
        id: '1',
        name: 'Bedroom',
        conditionRating: 3,
        notes: 'Needs work',
      );

      final updated = room.copyWith(name: 'Master Bedroom', conditionRating: 4);

      expect(updated.name, 'Master Bedroom');
      expect(updated.conditionRating, 4);
      expect(updated.notes, 'Needs work');
      expect(updated.id, '1');
    });

    test('copyWith() preserves unchanged fields', () {
      final room = Room(id: '1', name: 'Kitchen', roomTypeId: 4);

      final updated = room.copyWith(notes: 'New renovation');

      expect(updated.id, '1');
      expect(updated.name, 'Kitchen');
      expect(updated.roomTypeId, 4);
    });
  });
}
