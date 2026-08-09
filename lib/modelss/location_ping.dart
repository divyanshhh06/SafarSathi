import 'package:hive/hive.dart';

part 'location_ping.g.dart';

@HiveType(typeId: 0)
class LocationPing extends HiveObject {
  @HiveField(0)
  final String busId;

  @HiveField(1)
  final String routeId;

  @HiveField(2)
  final double lat;

  @HiveField(3)
  final double lng;

  @HiveField(4)
  final double speed;

  @HiveField(5)
  final double bearing;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  bool synced;

  LocationPing({
    required this.busId,
    required this.routeId,
    required this.lat,
    required this.lng,
    required this.speed,
    this.bearing = 0,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
    'busId': busId,
    'routeId': routeId,
    'lat': lat,
    'lng': lng,
    'speed': speed,
    'bearing': bearing,
    'timestamp': timestamp.toIso8601String(),
  };
}