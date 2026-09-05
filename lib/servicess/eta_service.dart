import 'dart:math';
import 'package:latlong2/latlong.dart';

/// ETA Status for route stops
enum StopEtaStatus { passed, approaching, upcoming }

/// Represents calculation result for a single stop on a route
class StopEtaResult {
  final String stopId;
  final String stopName;
  final LatLng position;
  final StopEtaStatus status;
  final int etaMinutes;
  final double distanceKm;
  final double bearingDegrees;
  final double adjustedSpeedKmh;
  final bool isCongested;

  const StopEtaResult({
    required this.stopId,
    required this.stopName,
    required this.position,
    required this.status,
    required this.etaMinutes,
    required this.distanceKm,
    required this.bearingDegrees,
    required this.adjustedSpeedKmh,
    required this.isCongested,
  });
}

/// Dynamic Geospatial ETA & Traffic Adjuster Service
/// Direct Dart port of etaEngine.js & trafficAdjuster.js (BE-3 Core Engines)
class EtaService {
  /// Gets current time-of-day traffic delay factor
  /// Morning Peak: 08:00 - 10:30 (+30% delay -> 1.3x)
  /// Evening Peak: 17:00 - 20:30 (+40% delay -> 1.4x)
  /// Off-Peak: 1.0x (Standard)
  static double getTimeOfDayFactor() {
    final now = DateTime.now();
    final double timeInDecimal = now.hour + (now.minute / 60.0);
    if (timeInDecimal >= 8.0 && timeInDecimal <= 10.5) {
      return 1.3;
    } else if (timeInDecimal >= 17.0 && timeInDecimal <= 20.5) {
      return 1.4;
    }
    return 1.0;
  }

  /// Calculates adjusted speed considering dynamic traffic congestion and time-of-day
  static Map<String, dynamic> getAdjustedSpeed({
    required double baseSpeedKmh,
    String? fromStopId,
    String? toStopId,
  }) {
    final double timeFactor = getTimeOfDayFactor();
    double segmentMultiplier = 1.0;

    if (fromStopId != null && toStopId != null) {
      final key = '$fromStopId-$toStopId';
      final reverseKey = '$toStopId-$fromStopId';
      final congestionMap = {
        'STOP_02-STOP_03': 1.4, // Hall Bazaar congestion
        'STOP_03-STOP_04': 1.8, // Golden Temple narrow street congestion
        'STOP_10-STOP_11': 1.5, // Ludhiana Clock Tower congestion
      };
      segmentMultiplier = congestionMap[key] ?? congestionMap[reverseKey] ?? 1.0;
    }

    final double totalDelayFactor = segmentMultiplier * timeFactor;
    final double rawSpeed = baseSpeedKmh > 5 ? baseSpeedKmh : 25.0; // 25 km/h urban baseline
    final double adjustedSpeed = max(10.0, rawSpeed / totalDelayFactor);

    return {
      'adjustedSpeed': adjustedSpeed,
      'delayFactor': totalDelayFactor,
      'isCongested': totalDelayFactor > 1.2,
    };
  }

  /// Calculates compass bearing (heading 0°-360°) between two points
  static double calculateBearing(LatLng from, LatLng to) {
    const Distance distance = Distance();
    double bearing = distance.bearing(from, to);
    if (bearing < 0) bearing += 360;
    return double.parse(bearing.toStringAsFixed(1));
  }

  /// Calculates straight-line/road distance in kilometers between two coordinates
  static double calculateDistanceKm(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  /// Computes real-time dynamic ETA in minutes between bus position and target position
  static int calculateEtaMinutes({
    required LatLng busPos,
    required LatLng targetPos,
    required double speedKmh,
    String? fromStopId,
    String? toStopId,
  }) {
    final distKm = calculateDistanceKm(busPos, targetPos);
    final speedData = getAdjustedSpeed(
      baseSpeedKmh: speedKmh,
      fromStopId: fromStopId,
      toStopId: toStopId,
    );
    final double effectiveSpeed = speedData['adjustedSpeed'] as double;
    final double etaMinutes = (distKm / effectiveSpeed) * 60;
    return max(1, etaMinutes.ceil());
  }

  /// Calculates full stop-by-stop ETA matrix for all upcoming stops on a route
  static List<StopEtaResult> calculateRouteEtaMatrix({
    required LatLng busPos,
    required double currentSpeedKmh,
    required List<Map<String, dynamic>> stops,
  }) {
    if (stops.isEmpty) return [];

    int nearestStopIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < stops.length; i++) {
      final stopPos = stops[i]['position'] as LatLng;
      final dist = calculateDistanceKm(busPos, stopPos);
      if (dist < minDistance) {
        minDistance = dist;
        nearestStopIndex = i;
      }
    }

    final List<StopEtaResult> results = [];
    double accumulatedMinutes = 0.0;

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final String stopId = stop['id']?.toString() ?? 'STOP_$i';
      final String stopName = stop['name']?.toString() ?? 'Bus Stop';
      final LatLng stopPos = stop['position'] as LatLng;

      if (i < nearestStopIndex) {
        results.add(StopEtaResult(
          stopId: stopId,
          stopName: stopName,
          position: stopPos,
          status: StopEtaStatus.passed,
          etaMinutes: 0,
          distanceKm: 0.0,
          bearingDegrees: 0.0,
          adjustedSpeedKmh: 0.0,
          isCongested: false,
        ));
      } else if (i == nearestStopIndex) {
        final dist = calculateDistanceKm(busPos, stopPos);
        final nextStopId = (i + 1 < stops.length) ? stops[i + 1]['id']?.toString() : stopId;
        final speedData = getAdjustedSpeed(
          baseSpeedKmh: currentSpeedKmh,
          fromStopId: stopId,
          toStopId: nextStopId,
        );
        final double adjSpeed = speedData['adjustedSpeed'] as double;
        final double segMinutes = (dist / adjSpeed) * 60;
        accumulatedMinutes += segMinutes;
        final bearing = calculateBearing(busPos, stopPos);

        results.add(StopEtaResult(
          stopId: stopId,
          stopName: stopName,
          position: stopPos,
          status: StopEtaStatus.approaching,
          etaMinutes: max(1, accumulatedMinutes.ceil()),
          distanceKm: double.parse(dist.toStringAsFixed(2)),
          bearingDegrees: bearing,
          adjustedSpeedKmh: adjSpeed,
          isCongested: speedData['isCongested'] as bool,
        ));
      } else {
        final prevStop = stops[i - 1];
        final LatLng prevPos = prevStop['position'] as LatLng;
        final String prevId = prevStop['id']?.toString() ?? 'STOP_${i - 1}';
        final interDist = calculateDistanceKm(prevPos, stopPos);
        final speedData = getAdjustedSpeed(
          baseSpeedKmh: currentSpeedKmh,
          fromStopId: prevId,
          toStopId: stopId,
        );
        final double adjSpeed = speedData['adjustedSpeed'] as double;
        final double segMinutes = (interDist / adjSpeed) * 60;
        accumulatedMinutes += segMinutes;

        results.add(StopEtaResult(
          stopId: stopId,
          stopName: stopName,
          position: stopPos,
          status: StopEtaStatus.upcoming,
          etaMinutes: max(1, accumulatedMinutes.ceil()),
          distanceKm: double.parse(interDist.toStringAsFixed(2)),
          bearingDegrees: 0.0,
          adjustedSpeedKmh: adjSpeed,
          isCongested: speedData['isCongested'] as bool,
        ));
      }
    }

    return results;
  }
}
