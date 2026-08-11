class PropertyTypeDto {
  final int id;
  final String name;
  final int sortOrder;
  final bool isActive;

  const PropertyTypeDto({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  factory PropertyTypeDto.fromJson(Map<String, dynamic> json) {
    return PropertyTypeDto(
      id: json['id'] as int,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int,
      isActive: json['isActive'] as bool,
    );
  }
}

class RoomTypeDto {
  final int id;
  final String description;

  const RoomTypeDto({required this.id, required this.description});

  factory RoomTypeDto.fromJson(Map<String, dynamic> json) {
    return RoomTypeDto(
      id: json['id'] as int,
      description: json['description'] as String,
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

class ConditionCategoryDto {
  final int id;
  final String description;

  const ConditionCategoryDto({required this.id, required this.description});

  factory ConditionCategoryDto.fromJson(Map<String, dynamic> json) {
    return ConditionCategoryDto(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
}

class ParkingTypeDto {
  final int id;
  final String description;

  const ParkingTypeDto({required this.id, required this.description});

  factory ParkingTypeDto.fromJson(Map<String, dynamic> json) {
    return ParkingTypeDto(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
}

class FacingDto {
  final int id;
  final String description;

  const FacingDto({required this.id, required this.description});

  factory FacingDto.fromJson(Map<String, dynamic> json) {
    return FacingDto(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
}

class ZoningDto {
  final int id;
  final String description;

  const ZoningDto({required this.id, required this.description});

  factory ZoningDto.fromJson(Map<String, dynamic> json) {
    return ZoningDto(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
}
