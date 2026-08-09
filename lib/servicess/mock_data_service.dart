import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../modelss/bus.dart';
import '../modelss/bus_route.dart';
import 'road_routing_service.dart';

/// Provides live bus position updates along actual road network geometries.
class MockDataService {
  static final Distance _distance = Distance();

  // Moga Punjab Bus Stops Dataset
  static final List<RouteStop> mogaStops = [
    const RouteStop(
      id: '2663261171',
      name: 'Bhugipura Chowk',
      city: 'Moga',
      state: 'Punjab',
      position: LatLng(30.8184434, 75.2190546),
      shelter: true,
    ),
    const RouteStop(
      id: '2677062869',
      name: 'Bus Stand',
      city: 'Moga',
      state: 'Punjab',
      position: LatLng(30.8119303, 75.3356210),
      shelter: false,
    ),
    const RouteStop(
      id: '5015094103',
      name: 'Dharamkot Bus Stop',
      city: 'Moga',
      state: 'Punjab',
      position: LatLng(30.9395274, 75.2383084),
      shelter: null,
    ),
    const RouteStop(
      id: '6639524485',
      name: 'Dagru Village',
      city: 'Moga',
      state: 'Punjab',
      position: LatLng(30.8341300, 75.0476956),
      shelter: null,
    ),
  ];

  static final List<BusRoute> routes = [
    BusRoute(
      id: 'M1',
      name: 'Route M1: Moga Central - Dagru Line',
      stops: [
        mogaStops[1], // Bus Stand
        mogaStops[0], // Bhugipura Chowk
        mogaStops[3], // Dagru Village
      ],
    ),
    BusRoute(
      id: 'M2',
      name: 'Route M2: Moga - Dharamkot Express',
      stops: [
        mogaStops[1], // Bus Stand
        mogaStops[0], // Bhugipura Chowk
        mogaStops[2], // Dharamkot Bus Stop
      ],
    ),
  ];

  static List<RouteStop> get allStops => mogaStops;

  final Map<String, _MockBusState> _state = {};
  final _controller = StreamController<List<Bus>>.broadcast();
  Timer? _timer;

  MockDataService() {
    for (final route in routes) {
      _state[route.id] = _MockBusState(
        busId: 'PB-29-${route.id}-101',
        routeId: route.id,
        path: route.path,
        segmentIndex: 0,
        progress: 0.0,
      );
    }
    _initRoadRoutes();
  }

  Future<void> _initRoadRoutes() async {
    for (final route in routes) {
      final roadPoints = await RoadRoutingService.getRoadPath(route.path);
      if (roadPoints.isNotEmpty) {
        _state[route.id] = _MockBusState(
          busId: 'PB-29-${route.id}-101',
          routeId: route.id,
          path: roadPoints,
          segmentIndex: 0,
          progress: 0.0,
        );
      }
    }
  }


  Stream<List<Bus>> get busUpdates {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    Future.microtask(_tick);
    return _controller.stream;
  }

  void _tick() {
    final buses = <Bus>[];
    for (final entry in _state.entries) {
      final state = entry.value;
      final bus = state.advance(_distance);
      buses.add(bus);
    }
    if (!_controller.isClosed) {
      _controller.add(buses);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

class _MockBusState {
  final String busId;
  final String routeId;
  final List<LatLng> path;
  int segmentIndex;
  double progress;
  bool forward = true;

  _MockBusState({
    required this.busId,
    required this.routeId,
    required this.path,
    required this.segmentIndex,
    required this.progress,
  });

  Bus advance(Distance distance) {
    if (path.length < 2) {
      return Bus(
        busId: busId,
        routeId: routeId,
        position: path.isNotEmpty ? path.first : const LatLng(30.8119, 75.3356),
        speedKmh: 0,
        bearing: 0,
      );
    }

    // Step smoothly along road nodes
    progress += 0.08;
    if (progress >= 1) {

      progress = 0;
      if (forward) {
        segmentIndex++;
        if (segmentIndex >= path.length - 1) {
          forward = false;
        }
      } else {
        segmentIndex--;
        if (segmentIndex <= 0) {
          forward = true;
        }
      }
    }

    final fromIndex = min(segmentIndex, path.length - 1);
    final toIndex = forward
        ? min(segmentIndex + 1, path.length - 1)
        : max(segmentIndex - 1, 0);

    final from = path[fromIndex];
    final to = path[toIndex];

    final lat = from.latitude + (to.latitude - from.latitude) * progress;
    final lng = from.longitude + (to.longitude - from.longitude) * progress;
    final position = LatLng(lat, lng);

    final bearing = (from == to) ? 0.0 : distance.bearing(from, to);
    final speed = 30 + Random().nextDouble() * 15;

    return Bus(
      busId: busId,
      routeId: routeId,
      position: position,
      speedKmh: speed,
      bearing: bearing,
    );
  }
}
