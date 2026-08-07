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

/// Represents a single live bus position update.
class Bus {
  final String busId;
  final String routeId;
  final LatLng position;
  final double speedKmh;
  final double bearing; // degrees, 0 = north
  final OccupancyLevel occupancy;

  Bus({
    required this.busId,
    required this.routeId,
    required this.position,
    required this.speedKmh,
    this.bearing = 0,
    this.occupancy = OccupancyLevel.seatsAvailable,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    OccupancyLevel parsedOccupancy = OccupancyLevel.seatsAvailable;
    final occString = json['occupancy'] as String?;
    if (occString == 'standingOnly') parsedOccupancy = OccupancyLevel.standingOnly;
    if (occString == 'packed') parsedOccupancy = OccupancyLevel.packed;

    return Bus(
      busId: json['busId'] as String,
      routeId: json['routeId'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      speedKmh: (json['speed'] as num).toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
      occupancy: parsedOccupancy,
    );
  }

  Bus copyWith({
    LatLng? position,
    double? speedKmh,
    double? bearing,
    OccupancyLevel? occupancy,
  }) {
    return Bus(
      busId: busId,
      routeId: routeId,
      position: position ?? this.position,
      speedKmh: speedKmh ?? this.speedKmh,
      bearing: bearing ?? this.bearing,
      occupancy: occupancy ?? this.occupancy,
    );
  }
}
