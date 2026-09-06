import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum OccupancyLevel {
  seatsAvailable, // Green
  standingOnly,   // Yellow
  packed,         // Red
}

extension OccupancyExtension on OccupancyLevel {
  String label(String langCode) {
    switch (this) {
      case OccupancyLevel.seatsAvailable:
        if (langCode == 'pa') return 'ਸੀਟਾਂ ਉਪਲਬਧ';
        if (langCode == 'hi') return 'सीटें उपलब्ध';
        return 'Seats Available';
      case OccupancyLevel.standingOnly:
        if (langCode == 'pa') return 'ਖੜ੍ਹੇ ਹੋਣ ਦੀ ਜਗ੍ਹਾ';
        if (langCode == 'hi') return 'केवल खड़े होकर';
        return 'Standing Only';
      case OccupancyLevel.packed:
        if (langCode == 'pa') return 'ਪੂਰਾ ਭਰਿਆ ਹੋਇਆ';
        if (langCode == 'hi') return 'खचाखच भरा हुआ';
        return 'Packed / Overcrowded';
    }
  }

  Color get color {
    switch (this) {
      case OccupancyLevel.seatsAvailable:
        return const Color(0xFF2E7D32); // Green
      case OccupancyLevel.standingOnly:
        return const Color(0xFFF57F17); // Yellow/Orange
      case OccupancyLevel.packed:
        return const Color(0xFFC62828); // Red
    }
  }
}

/// Represents a single live bus fleet position update.
class BusState {
  final String busId;
  final String routeId;
  final LatLng position;
  final double speed;
  final double bearing; // degrees, 0 = north
  final DateTime lastUpdated;
  final bool isDwelling; // true when speed == 0 at a stop
  final String? currentStopName;
  final String direction; // 'forward' (to terminus) or 'returning' (to start)
  final OccupancyLevel occupancy;

  double get speedKmh => speed;

  BusState({
    required this.busId,
    required this.routeId,
    required this.position,
    required this.speed,
    this.bearing = 0,
    DateTime? lastUpdated,
    bool? isDwelling,
    this.currentStopName,
    this.direction = 'forward',
    this.occupancy = OccupancyLevel.seatsAvailable,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        isDwelling = isDwelling ?? (speed == 0.0);

  factory BusState.fromJson(Map<String, dynamic> json) {
    OccupancyLevel parsedOccupancy = OccupancyLevel.seatsAvailable;
    final occString = json['occupancy'] as String?;
    if (occString == 'standingOnly') parsedOccupancy = OccupancyLevel.standingOnly;
    if (occString == 'packed') parsedOccupancy = OccupancyLevel.packed;

    final spd = (json['speed'] as num?)?.toDouble() ?? 0.0;

    return BusState(
      busId: json['busId'] as String? ?? 'BUS_UNKNOWN',
      routeId: json['routeId'] as String? ?? 'ROUTE_UNKNOWN',
      position: LatLng(
        (json['lat'] as num?)?.toDouble() ?? 0.0,
        (json['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      speed: spd,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      isDwelling: json['isDwelling'] as bool? ?? (spd == 0.0),
      currentStopName: json['currentStopName'] as String?,
      direction: json['direction'] as String? ?? 'forward',
      occupancy: parsedOccupancy,
    );
  }

  BusState copyWith({
    LatLng? position,
    double? speed,
    double? speedKmh,
    double? bearing,
    DateTime? lastUpdated,
    bool? isDwelling,
    String? currentStopName,
    String? direction,
    OccupancyLevel? occupancy,
  }) {
    final effectiveSpeed = speed ?? speedKmh ?? this.speed;
    return BusState(
      busId: busId,
      routeId: routeId,
      position: position ?? this.position,
      speed: effectiveSpeed,
      bearing: bearing ?? this.bearing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDwelling: isDwelling ?? (effectiveSpeed == 0.0),
      currentStopName: currentStopName ?? this.currentStopName,
      direction: direction ?? this.direction,
      occupancy: occupancy ?? this.occupancy,
    );
  }
}

typedef Bus = BusState;
