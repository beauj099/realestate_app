class Room {
  final String id;
  final String name;
  final int roomTypeId;
  final String? roomTypeOther;
  final int? conditionRating;
  final List<String> features;
  final List<int> featureIds;
  final String notes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    required this.id,
    required this.name,
    this.roomTypeId = 1,
    this.roomTypeOther,
    this.conditionRating,
    this.features = const [],
    this.featureIds = const [],
    this.notes = '',
    this.photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Room copyWith({
    String? id,
    String? name,
    int? roomTypeId,
    String? roomTypeOther,
    int? conditionRating,
    List<String>? features,
    List<int>? featureIds,
    String? notes,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      roomTypeOther: roomTypeOther ?? this.roomTypeOther,
      conditionRating: conditionRating ?? this.conditionRating,
      features: features ?? this.features,
      featureIds: featureIds ?? this.featureIds,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
