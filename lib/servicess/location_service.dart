import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../modelss/location_ping.dart';
import 'socket_service.dart';

class LocationService {
  static const _pingInterval = Duration(seconds: 7);
  static const _boxName = 'trip_pings';

  final SocketService _socketService;
  Timer? _pollTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushInProgress = false;

  LocationService({SocketService? socketService})
      : _socketService = socketService ?? SocketService();

  Future<bool> _ensurePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return false;
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> startTracking({
    required String busId,
    required String routeId,
  }) async {
    _socketService.connect(routeId: routeId);

    final hasPermission = await _ensurePermissions();

    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
          final online = results.any((r) => r != ConnectivityResult.none);
          if (online) flushQueue();
        });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pingInterval, (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final ping = LocationPing(
          busId: busId,
          routeId: routeId,
          lat: position.latitude,
          lng: position.longitude,
          speed: position.speed * 3.6,
          bearing: position.heading,
          timestamp: DateTime.now(),
        );

        final box = Hive.box<LocationPing>(_boxName);
        await box.add(ping);

        await flushQueue();
      } catch (e) {
        // ignore: avoid_print
        print('Location read failed, will retry next tick: $e');
      }
    });
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
    final box = Hive.box<LocationPing>(_boxName);
    return box.values.where((p) => !p.synced).length;
  }
}