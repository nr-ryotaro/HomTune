class Room {
  final String id;
  final String name;
  final String type;
  final int floor;
  final RoomCoordinates coordinates;
  final List<String> devices;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.floor,
    required this.coordinates,
    required this.devices,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      floor: json['floor'] ?? 1,
      coordinates: RoomCoordinates.fromJson(json['coordinates'] ?? {}),
      devices: (json['devices'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'floor': floor,
      'coordinates': coordinates.toJson(),
      'devices': devices,
    };
  }
}

class RoomCoordinates {
  final double x;
  final double y;
  final double width;
  final double height;

  RoomCoordinates({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory RoomCoordinates.fromJson(Map<String, dynamic> json) {
    try {
      return RoomCoordinates(
        x: ((json['x'] ?? 0) as num).toDouble(),
        y: ((json['y'] ?? 0) as num).toDouble(),
        width: ((json['width'] ?? 100) as num).toDouble(),
        height: ((json['height'] ?? 100) as num).toDouble(),
      );
    } catch (e) {
      // フォールバック: デフォルト値
      return RoomCoordinates(
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}

class FloorPlan {
  final String id;
  final String name;
  final double scale;
  final double width;
  final double height;
  final List<FloorPlanRoom> rooms;
  final List<Wall>? walls;

  FloorPlan({
    required this.id,
    required this.name,
    required this.scale,
    required this.width,
    required this.height,
    required this.rooms,
    this.walls,
  });

  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    try {
      return FloorPlan(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        scale: ((json['scale'] ?? 1.0) as num).toDouble(),
        width: ((json['width'] ?? 800) as num).toDouble(),
        height: ((json['height'] ?? 700) as num).toDouble(),
        rooms: (json['rooms'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return FloorPlanRoom.fromJson(e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing floor plan room: $e');
                    return null;
                  }
                })
                .whereType<FloorPlanRoom>()
                .toList() ??
            [],
        walls: (json['walls'] as List<dynamic>?)
            ?.map((e) {
              try {
                return Wall.fromJson(e as Map<String, dynamic>);
              } catch (e) {
                return null;
              }
            })
            .whereType<Wall>()
            .toList(),
      );
    } catch (e) {
      print('Error parsing FloorPlan: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scale': scale,
      'width': width,
      'height': height,
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'walls': walls?.map((e) => e.toJson()).toList(),
    };
  }
}

class FloorPlanRoom {
  final String id;
  final String name;
  final String type;
  final RoomCoordinates coordinates;
  final String color;
  final String borderColor;
  final List<DevicePlacement> devices;

  FloorPlanRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.coordinates,
    required this.color,
    required this.borderColor,
    required this.devices,
  });

  factory FloorPlanRoom.fromJson(Map<String, dynamic> json) {
    try {
      return FloorPlanRoom(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '',
        coordinates: RoomCoordinates.fromJson(json['coordinates'] ?? {}),
        color: json['color'] ?? '#FAFAFA',
        borderColor: json['borderColor'] ?? '#E0E0E0',
        devices: (json['devices'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return DevicePlacement.fromJson(e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing device placement: $e');
                    return null;
                  }
                })
                .whereType<DevicePlacement>()
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing FloorPlanRoom: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'coordinates': coordinates.toJson(),
      'color': color,
      'borderColor': borderColor,
      'devices': devices.map((e) => e.toJson()).toList(),
    };
  }
}

class DevicePlacement {
  final String deviceId;
  final double x;
  final double y;
  final String icon;

  DevicePlacement({
    required this.deviceId,
    required this.x,
    required this.y,
    required this.icon,
  });

  factory DevicePlacement.fromJson(Map<String, dynamic> json) {
    return DevicePlacement(
      deviceId: json['deviceId'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'x': x,
      'y': y,
      'icon': icon,
    };
  }
}

class Wall {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  Wall({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory Wall.fromJson(Map<String, dynamic> json) {
    return Wall(
      x1: (json['x1'] ?? 0).toDouble(),
      y1: (json['y1'] ?? 0).toDouble(),
      x2: (json['x2'] ?? 0).toDouble(),
      y2: (json['y2'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    };
  }
}
