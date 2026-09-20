import 'package:flutter/material.dart';

/// The condition band an agent assigns to a room.
///
/// Stored as the [level] integer in `Condition.ConditionRating`, which is a
/// `DECIMAL(3,1)` with no range constraint — so widening from four bands to six
/// needs no database change. Existing rows written under the old 1–4 scale are
/// mapped by [fromStored] so historic listings still read sensibly.
enum ConditionRating {
  toBeRemodeled(1, 'To be remodeled'),
  toBeRenovated(2, 'To be renovated'),
  average(3, 'Average'),
  good(4, 'Good'),
  veryGood(5, 'Very good'),
  excellent(6, 'Excellent');

  final int level;
  final String label;

  const ConditionRating(this.level, this.label);

  /// Colour ramp from needs-work through to excellent.
  Color color(Color pending, Color complete, Color muted) {
    switch (this) {
      case ConditionRating.toBeRemodeled:
      case ConditionRating.toBeRenovated:
        return pending;
      case ConditionRating.average:
        return muted;
      case ConditionRating.good:
      case ConditionRating.veryGood:
      case ConditionRating.excellent:
        return complete;
    }
  }

  /// Resolves a stored rating.
  ///
  /// Values 1–6 map directly. Anything outside that came from the retired 1–4
  /// scale or a bad write, so it is clamped into range rather than dropped.
  static ConditionRating? fromStored(num? stored) {
    if (stored == null) return null;
    final rounded = stored.round();
    if (rounded < 1) return ConditionRating.toBeRemodeled;
    if (rounded > values.length) return ConditionRating.excellent;
    return values[rounded - 1];
  }
}
