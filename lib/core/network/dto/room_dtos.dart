class CreateRoomRequest {
  final String name;
  final int roomTypeId;
  final String? roomTypeOther;
  final String? photoUrl;

  const CreateRoomRequest({
    required this.name,
    required this.roomTypeId,
    this.roomTypeOther,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'roomTypeId': roomTypeId,
        if (roomTypeOther != null) 'roomTypeOther': roomTypeOther,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}

class UpdateRoomRequest {
  final String? name;
  final int? roomTypeId;
  final String? roomTypeOther;
  final String? photoUrl;

  const UpdateRoomRequest({
    this.name,
    this.roomTypeId,
    this.roomTypeOther,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (roomTypeId != null) 'roomTypeId': roomTypeId,
        if (roomTypeOther != null) 'roomTypeOther': roomTypeOther,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}

class UpsertRoomConditionRequest {
  final int? conditionRating;
  final String? notes;
  final int conditionCategoryId;

  const UpsertRoomConditionRequest({
    this.conditionRating,
    this.notes,
    required this.conditionCategoryId,
  });

  Map<String, dynamic> toJson() => {
        if (conditionRating != null) 'conditionRating': conditionRating,
        if (notes != null) 'notes': notes,
        'conditionCategoryId': conditionCategoryId,
      };
}

class LinkFeatureRequest {
  final int featureId;

  const LinkFeatureRequest({required this.featureId});

  Map<String, dynamic> toJson() => {'featureId': featureId};
}

class AddCustomFeatureRequest {
  final String description;

  const AddCustomFeatureRequest({required this.description});

  Map<String, dynamic> toJson() => {'description': description};
}

class RoomConditionDto {
  final int id;
  final int listingRoomId;
  final int? conditionRating;
  final String? notes;
  final int conditionCategoryId;

  const RoomConditionDto({
    required this.id,
    required this.listingRoomId,
    this.conditionRating,
    this.notes,
    required this.conditionCategoryId,
  });

  factory RoomConditionDto.fromJson(Map<String, dynamic> json) {
    return RoomConditionDto(
      id: json['id'] as int,
      listingRoomId: json['listingRoomId'] as int,
      conditionRating: json['conditionRating'] as int?,
      notes: json['notes'] as String?,
      conditionCategoryId: json['conditionCategoryId'] as int,
    );
  }
}

class CustomFeatureDto {
  final int id;
  final int listingRoomId;
  final String description;

  const CustomFeatureDto({
    required this.id,
    required this.listingRoomId,
    required this.description,
  });

  factory CustomFeatureDto.fromJson(Map<String, dynamic> json) {
    return CustomFeatureDto(
      id: json['id'] as int,
      listingRoomId: json['listingRoomId'] as int,
      description: json['description'] as String,
    );
  }
}

class RoomDto {
  final int id;
  final int listingId;
  final String name;
  final int roomTypeId;
  final String? roomTypeOther;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RoomConditionDto? condition;
  final List<FeatureDto> features;
  final List<CustomFeatureDto> customFeatures;

  const RoomDto({
    required this.id,
    required this.listingId,
    required this.name,
    required this.roomTypeId,
    this.roomTypeOther,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.condition,
    this.features = const [],
    this.customFeatures = const [],
  });

  factory RoomDto.fromJson(Map<String, dynamic> json) {
    return RoomDto(
      id: json['id'] as int,
      listingId: json['listingId'] as int,
      name: json['name'] as String,
      roomTypeId: json['roomTypeId'] as int,
      roomTypeOther: json['roomTypeOther'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      condition: json['condition'] != null
          ? RoomConditionDto.fromJson(json['condition'] as Map<String, dynamic>)
          : null,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => FeatureDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customFeatures: (json['customFeatures'] as List<dynamic>?)
              ?.map(
                  (e) => CustomFeatureDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FeatureDto {
  final int id;
  final String category;
  final String description;

  const FeatureDto({
    required this.id,
    required this.category,
    required this.description,
  });

  factory FeatureDto.fromJson(Map<String, dynamic> json) {
    return FeatureDto(
      id: json['id'] as int,
      category: json['category'] as String,
      description: json['description'] as String,
    );
  }
}
