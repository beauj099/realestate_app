enum FacingDirection {
  north,
  east,
  south,
  west,
}

extension FacingDirectionExtension on FacingDirection {
  String get displayString {
    switch (this) {
      case FacingDirection.north:
        return 'North';
      case FacingDirection.east:
        return 'East';
      case FacingDirection.south:
        return 'South';
      case FacingDirection.west:
        return 'West';
    }
  }

  static FacingDirection fromString(String val) {
    switch (val.trim().toLowerCase()) {
      case 'east':
        return FacingDirection.east;
      case 'south':
        return FacingDirection.south;
      case 'west':
        return FacingDirection.west;
      case 'north':
      default:
        return FacingDirection.north;
    }
  }
}
