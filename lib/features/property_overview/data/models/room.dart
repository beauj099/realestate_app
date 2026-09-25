/// Sentinel for [Room.copyWith], so an explicit `null` can clear [Room.score].
const Object _unset = Object();

/// One photo of a room: a server photo ([id] set, [path] its URL) or a
/// freshly taken shot still on the device ([id] null, [path] a local file).
class RoomPhoto {
  final int? id;
  final String path;

  const RoomPhoto({this.id, required this.path});

  bool get isUploaded => id != null;
}

class RoomFeature {
  final String description;
  final int? featureId;
  final int? customId;

  const RoomFeature({required this.description, this.featureId, this.customId});

  bool get isPredefined => featureId != null;

  bool get isPersisted => featureId != null || customId != null;

  RoomFeature copyWith({int? featureId, int? customId}) {
    return RoomFeature(
      description: description,
      featureId: featureId ?? this.featureId,
      customId: customId ?? this.customId,
    );
  }
}

class Room {
  final String id;
  final String name;
  final int roomTypeId;
  final String? roomTypeOther;
  final int? conditionRating;

  /// The agent's overall 0–10 score for the room, in half steps. Separate from
  /// [conditionRating]; averaged across rooms into the house score. Null until
  /// the agent scores the room.
  final double? score;

  final List<RoomFeature> features;
  final List<String> hiddenFeatures;
  final String notes;
  /// Up to [maxPhotos] photos, the first being the room's cover.
  final List<RoomPhoto> photos;

  static const int maxPhotos = 20;

  /// The cover photo, if any.
  String? get photoUrl => photos.isEmpty ? null : photos.first.path;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    required this.id,
    required this.name,
    this.roomTypeId = 1,
    this.roomTypeOther,
    this.conditionRating,
    this.score,
    this.features = const [],
    this.hiddenFeatures = const [],
    this.notes = '',
    this.photos = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Room copyWith({
    String? id,
    String? name,
    int? roomTypeId,
    String? roomTypeOther,
    int? conditionRating,
    Object? score = _unset,
    List<RoomFeature>? features,
    List<String>? hiddenFeatures,
    String? notes,
    List<RoomPhoto>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      roomTypeOther: roomTypeOther ?? this.roomTypeOther,
      conditionRating: conditionRating ?? this.conditionRating,
      score: identical(score, _unset) ? this.score : score as double?,
      features: features ?? this.features,
      hiddenFeatures: hiddenFeatures ?? this.hiddenFeatures,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
