import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../modelss/bus.dart';
import '../modelss/bus_route.dart';
import '../servicess/socket_service.dart';
import '../servicess/mock_data_service.dart';
import '../servicess/road_routing_service.dart';
import '../widget/route_search_bar.dart';
import '../widget/route_sheet.dart';
import '../widget/animated_bus_marker.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  State<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen> {
  final MapController _mapController = MapController();
  final SocketService _socketService = SocketService();

  List<Bus> _liveBuses = [];
  final Map<String, LatLng> _animatedPositions = {};
  List<Polyline> _routePolylines = [];
  String _currentLang = 'en'; // 'en', 'pa', 'hi'

  // Center on Moga, Punjab Bus Stand
  static const LatLng _initialCenter = LatLng(30.8119303, 75.3356210);

  @override
  void initState() {
    super.initState();
    _loadRoadPolylines();
    _socketService.connect().listen((buses) {
      if (mounted) {
        setState(() {
          _liveBuses = buses;
          for (final bus in buses) {
            _animatedPositions.putIfAbsent(bus.busId, () => bus.position);
          }
        });
      }
    });
  }

  Future<void> _loadRoadPolylines() async {
    final polylines = <Polyline>[];
    final colors = [
      const Color(0xFF2E3192),
      const Color(0xFFE65100),
    ];

    int colorIndex = 0;
    for (final route in MockDataService.routes) {
      final roadPoints = await RoadRoutingService.getRoadPath(route.path);
      polylines.add(
        Polyline(
          points: roadPoints.isNotEmpty ? roadPoints : route.path,
          strokeWidth: 4.5,
          color: colors[colorIndex % colors.length],
        ),
      );
      colorIndex++;
    }

    if (mounted) {
      setState(() {
        _routePolylines = polylines;
      });
    }
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  void _onRouteSelected(BusRoute route) {
    _socketService.joinRoute(route.id);
    _mapController.move(route.stops.first.position, 14);

    final busesOnRoute =
        _liveBuses.where((b) => b.routeId == route.id).toList();

    RouteSheet.show(
      context,
      route,
      busesOnRoute,
      currentLang: _currentLang,
      onOccupancyReported: (newOccupancy) {
        // Send occupancy report payload to BE-2 API & BE-1 WebSockets
        if (busesOnRoute.isNotEmpty) {
          _socketService.reportOccupancy(busesOnRoute.first.busId, newOccupancy);
        }
        setState(() {
          _liveBuses = _liveBuses.map((bus) {
            if (bus.routeId == route.id) {
              return bus.copyWith(occupancy: newOccupancy);
            }
            return bus;
          }).toList();
        });
      },

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.transit_commuter_app',
              ),
              // Road Route Polylines Layer
              if (_routePolylines.isNotEmpty)
                PolylineLayer(polylines: _routePolylines),
              // Bus Stops Marker Layer (Moga Dataset)
              MarkerLayer(
                markers: MockDataService.allStops.map((stop) {
                  final hasShelter = stop.shelter == true;
                  final localizedName = stop.getLocalizedName(_currentLang);
                  return Marker(
                    point: stop.position,
                    width: 38,
                    height: 38,
                    child: Tooltip(
                      message: '$localizedName, ${stop.city}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasShelter
                              ? const Color(0xFF2E3192)
                              : Colors.deepOrangeAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Live Bus Position Markers Layer with Occupancy status
              MarkerLayer(
                markers: _liveBuses.map((bus) {
                  return Marker(
                    point: _animatedPositions[bus.busId] ?? bus.position,
                    width: 65,
                    height: 65,
                    child: AnimatedBusMarker(
                      target: bus.position,
                      bearing: bus.bearing,
                      speedKmh: bus.speedKmh,
                      occupancy: bus.occupancy,
                      onPositionUpdate: (pos) {
                        if (mounted) {
                          setState(() {
                            _animatedPositions[bus.busId] = pos;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RouteSearchBar(
                routes: MockDataService.routes,
                currentLang: _currentLang,
                onLanguageChanged: (lang) {
                  setState(() {
                    _currentLang = lang;
                  });
                },
                onResultSelected: _onRouteSelected,
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: () => _mapController.move(_initialCenter, 13),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
