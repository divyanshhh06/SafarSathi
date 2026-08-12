import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../modelss/bus.dart';
import '../modelss/bus_route.dart';
import '../modelss/stop.dart';
import '../servicess/socket_service.dart';
import '../servicess/road_routing_service.dart';
import '../servicess/api_service.dart';
import '../widget/route_search_bar.dart';
import '../widget/route_sheet.dart';
import '../widget/animated_bus_marker.dart';
import '../widget/bus_info_card.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  State<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen> {
  final MapController _mapController = MapController();
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  List<Bus> _liveBuses = [];
  List<Polyline> _routePolylines = [];
  List<BusStop> _apiStops = [];
  List<BusRoute> _apiRoutes = [];
  List<BusRoute> _sortedRoutes = [];
  Bus? _selectedBus;

  String _currentLang = 'en'; // 'en', 'pa', 'hi'
  String _busQuery = '';
  bool _sortByStops = false;

  // Center on Moga, Punjab Bus Stand
  static const LatLng _initialCenter = LatLng(30.8119303, 75.3356210);

  @override
  void initState() {
    super.initState();
    _loadRoadPolylines();
    _loadApiStops();
    _loadApiRoutes();
    _socketService.connect().listen((buses) {
      if (mounted) {
        setState(() {
          _liveBuses = buses;
        });
      }
    });
  }

  Future<void> _loadApiRoutes() async {
    try {
      final routes = await _apiService.getRoutes();
      if (mounted) {
        setState(() {
          _apiRoutes = routes;
          _applyRouteSort();
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load routes from API: $e');
    }
  }

  void _applyRouteSort() {
    final sorted = List<BusRoute>.from(_apiRoutes);
    if (_sortByStops) {
      sorted.sort((a, b) {
        final cmp = a.stops.length.compareTo(b.stops.length);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } else {
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    setState(() {
      _sortedRoutes = sorted;
    });
  }

  Future<void> _loadApiStops() async {
    try {
      final stops = await _apiService.getStops();
      if (mounted) {
        setState(() {
          _apiStops = stops;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load stops from API: $e');
    }
  }


  Future<void> _loadRoadPolylines() async {
    final polylines = <Polyline>[];
    final colors = [
      const Color(0xFF2E3192),
      const Color(0xFFE65100),
    ];

    int colorIndex = 0;
    for (final route in _apiRoutes) {
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

  void _onBusTapped(Bus bus) {
    final route = _apiRoutes.firstWhereOrNull((r) => r.id == bus.routeId);
    setState(() {
      _selectedBus = bus;
    });
    _showBusInfoSheet(context, bus, route);
  }

  void _showBusInfoSheet(BuildContext context, Bus bus, BusRoute? route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: BusInfoCard(
          bus: bus,
          route: route,
          onClose: () {
            Navigator.pop(sheetContext);
            setState(() => _selectedBus = null);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuses = _busQuery.isEmpty
        ? _liveBuses
        : _liveBuses.where((bus) {
            final route = _apiRoutes.firstWhereOrNull((r) => r.id == bus.routeId);
            final routeName = route?.getLocalizedName(_currentLang).toLowerCase() ?? '';
            return bus.busId.toLowerCase().contains(_busQuery.toLowerCase()) ||
                bus.routeId.toLowerCase().contains(_busQuery.toLowerCase()) ||
                routeName.contains(_busQuery.toLowerCase());
          }).toList();

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
              // Bus Stops Marker Layer (API-backed)
              MarkerLayer(
                markers: _apiStops.map((stop) {
                  final hasShelter = stop.shelter == true;
                  return Marker(
                    point: stop.position,
                    width: 38,
                    height: 38,
                    child: Tooltip(
                      message: '${stop.name}, ${stop.city}',
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
                markers: filteredBuses.map((bus) {
                  return Marker(
                    point: bus.position,
                    width: 65,
                    height: 65,
                    child: GestureDetector(
                      onTap: () => _onBusTapped(bus),
                      child: AnimatedBusMarker(
                        target: bus.position,
                        bearing: bus.bearing,
                        speedKmh: bus.speedKmh,
                        occupancy: bus.occupancy,
                      ),
                    ),
                  );
                }).toList(),
              ),

            ],
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: RouteSearchBar(
                    routes: _sortedRoutes,
                    stops: _apiStops,
                    currentLang: _currentLang,
                    onLanguageChanged: (lang) {
                      setState(() {
                        _currentLang = lang;
                      });
                    },
                    onResultSelected: _onRouteSelected,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _BusFinderField(
                        query: _busQuery,
                        onChanged: (q) => setState(() => _busQuery = q),
                        count: filteredBuses.length,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortRoutesButton(
                      sortByStops: _sortByStops,
                      onToggle: (v) {
                        setState(() => _sortByStops = v);
                        _applyRouteSort();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: _selectedBus != null ? 280 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'admin_switch',
                  backgroundColor: const Color(0xFF1E1F57),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                  label: const Text('Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: () => _mapController.move(_initialCenter, 13),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          if (_selectedBus != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: BusInfoCard(
                bus: _selectedBus!,
                route: _apiRoutes.firstWhereOrNull((r) => r.id == _selectedBus!.routeId),
                onClose: () => setState(() => _selectedBus = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _BusFinderField extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final int count;

  const _BusFinderField({
    required this.query,
    required this.onChanged,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Find bus (ID / route)...',
        prefixIcon: const Icon(Icons.directions_bus_rounded, size: 20),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SortRoutesButton extends StatelessWidget {
  final bool sortByStops;
  final ValueChanged<bool> onToggle;

  const _SortRoutesButton({
    required this.sortByStops,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => onToggle(!sortByStops),
      icon: Icon(
        sortByStops ? Icons.sort_by_alpha_rounded : Icons.sort_rounded,
        size: 20,
      ),
      tooltip: sortByStops ? 'Sort by name' : 'Sort by stops',
    );
  }
}

