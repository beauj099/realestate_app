import 'enums/room_category.dart';
import 'room.dart';

/// Wording, formatting and weighting for room scores (0–10) and the house
/// score (a percentage).
abstract final class RoomScore {
  static const double min = 0;
  static const double max = 10;

  /// Slider steps: half points.
  static const int divisions = 20;

  /// Plain-language band for a 0–10 score, e.g. 7.5 → "Very good".
  static String label(double score) {
    if (score < 3) return 'Poor';
    if (score < 5) return 'Fair';
    if (score < 7) return 'Good';
    if (score < 9) return 'Very good';
    return 'Excellent';
  }

  /// "7.5" or "8" — no trailing ".0".
  static String format(double score) {
    final rounded = (score * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }

  /// How much a room counts towards the suggested house score.
  ///
  /// Buyers and valuers weigh the rooms that are expensive to put right —
  /// kitchen, main bedroom, bathrooms, main living areas — far more than a
  /// scullery or storeroom, so a straight average would understate a house
  /// whose important rooms are good (or overstate one whose aren't). The
  /// room's name is checked first, since a category like "Kitchen & Utility"
  /// holds both the kitchen and the pantry; the category is the fallback,
  /// covering renamed and custom rooms.
  static double weightFor(Room room) {
    final name = room.name.toLowerCase();
    bool has(List<String> words) => words.any(name.contains);

    if (has(['scullery', 'laundry', 'pantry', 'toilet', 'powder'])) return 1;
    if (has(['storeroom', 'store room', 'workshop', 'loft', 'staff', 'wine'])) {
      return 0.5;
    }
    if (has(['kitchen'])) return 3;
    if (has(['main bedroom', 'master'])) return 2.5;
    if (has(['bathroom', 'en-suite', 'ensuite'])) return 2;
    if (has(['lounge', 'living', 'open-plan', 'family'])) return 2;

    switch (RoomCategoryExtension.categoryForRoomTypeId(room.roomTypeId)) {
      case RoomCategory.bedroom:
        return 1.5;
      case RoomCategory.bathroom:
        return 2;
      case RoomCategory.livingSpaces:
        return 1.5;
      case RoomCategory.kitchenAndUtility:
        return 1;
      case RoomCategory.workAndStudy:
      case RoomCategory.entertainment:
        return 1;
      case RoomCategory.additional:
        return 0.75;
    }
  }

  /// Weighted average of the scored rooms as a percentage (0–100), or null
  /// when no room is scored. Unscored rooms are left out, not counted as 0.
  static double? suggestedHousePercent(Iterable<Room> rooms) {
    var total = 0.0;
    var weights = 0.0;
    for (final room in rooms) {
      final score = room.score;
      if (score == null) continue;
      final w = weightFor(room);
      total += score * w;
      weights += w;
    }
    if (weights == 0) return null;
    return (total / weights * 10 * 10).round() / 10;
  }

  /// "72%" — house scores are shown as whole percentages.
  static String percent(double value) => '${value.round()}%';
}
