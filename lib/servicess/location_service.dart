import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import '../modelss/location_ping.dart';
import 'socket_service.dart';

/// Pure Route-Driven Telemetry Service for Driver Trips.
/// Operates without physical device GPS permissions — when the driver selects a route
/// and starts a trip, it automatically drives the bus along the selected route geometry,
/// streaming location pings, computing ETA, and reporting live telemetry.
class LocationService {
  static const _pingInterval = Duration(seconds: 2);
  static const _boxName = 'trip_pings';

  final SocketService _socketService;
  Timer? _pollTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushInProgress = false;

  List<LatLng> _densePath = [];
  int _stepIndex = 0;

  LocationService({SocketService? socketService})
      : _socketService = socketService ?? SocketService();

  /// Generates a smooth, dense path of points between route waypoints for realistic driving animation.
  List<LatLng> _generateDensePath(List<LatLng> waypoints, {int pointsPerSegment = 20}) {
    if (waypoints.isEmpty) return [];
    if (waypoints.length == 1) return waypoints;

    final List<LatLng> dense = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      for (int step = 0; step < pointsPerSegment; step++) {
        final t = step / pointsPerSegment;
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lng = start.longitude + (end.longitude - start.longitude) * t;
        dense.add(LatLng(lat, lng));
      }
    }
    dense.add(waypoints.last);
    return dense;
  }

  Future<void> startTracking({
    required String busId,
    required String routeId,
    List<LatLng>? routePath,
  }) async {
    _socketService.connect(routeId: routeId);

    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) flushQueue();
    });

    final List<LatLng> baseWaypoints = (routePath != null && routePath.length >= 2)
        ? routePath
        : const [
            LatLng(30.8119303, 75.3356210), // Moga Bus Stand
            LatLng(30.8354, 75.4312),       // Ajitwal
            LatLng(30.7844, 75.4746),       // Jagraon
            LatLng(30.900965, 75.8572758),  // Ludhiana Bus Stand
          ];

    _densePath = _generateDensePath(baseWaypoints, pointsPerSegment: 25);
    _stepIndex = 0;

    Future<void> emitTick() async {
      if (_densePath.isEmpty) return;

      final currentPt = _densePath[_stepIndex % _densePath.length];
      final nextPt = _densePath[(_stepIndex + 1) % _densePath.length];
      _stepIndex = (_stepIndex + 1) % _densePath.length;

      final lat = currentPt.latitude;
      final lng = currentPt.longitude;

      const Distance distance = Distance();
      double bearing = distance.bearing(currentPt, nextPt);
      if (bearing < 0) bearing += 360;

      final speed = 45.0 + (_stepIndex % 12); // Smooth 45-57 km/h driving speed

      final ping = LocationPing(
        busId: busId,
        routeId: routeId,
        lat: lat,
        lng: lng,
        speed: speed,
        bearing: bearing,
        timestamp: DateTime.now(),
      );

      try {
        final box = Hive.box<LocationPing>(_boxName);
        await box.add(ping);
      } catch (_) {}

      await flushQueue();
    }

    // Immediately emit first location ping (0ms delay)
    await emitTick();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pingInterval, (_) => emitTick());
  }

  Future<void> flushQueue() async {
    if (_flushInProgress) return;
    _flushInProgress = true;

    try {
      final box = Hive.box<LocationPing>(_boxName);
      final unsynced = box.values.where((p) => !p.synced).toList();

      for (final ping in unsynced) {
        final sent = await _socketService.reportDriverLocation(ping.toJson());
        if (!sent) break;
        ping.synced = true;
        await ping.save();
      }

      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final stale = box.values
          .where((p) => p.synced && p.timestamp.isBefore(cutoff))
          .toList();
      for (final p in stale) {
        await p.delete();
      }
    } catch (_) {
    } finally {
      _flushInProgress = false;
    }
  }

  Future<void> stopTracking() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    await flushQueue();
  }

  int get pendingCount {
    try {
      final box = Hive.box<LocationPing>(_boxName);
      return box.values.where((p) => !p.synced).length;
    } catch (_) {
      return 0;
    }
  }
}