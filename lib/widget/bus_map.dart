
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../modelss/bus.dart';

class BusMap extends StatelessWidget {
  final List<Bus> buses;
  final LatLng center;
  final double zoom;

  const BusMap({
    super.key,
    required this.buses,
    this.center = const LatLng(23.2599, 77.4126),
    this.zoom = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.safarsathi.transport_app',
          ),

          MarkerLayer(
            markers: buses.map((bus) {
              return Marker(
                point: bus.position,
                width: 52,
                height: 52,
                child: _BusMarker(bus: bus),
              );
            }).toList(),
          ),

          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusMarker extends StatelessWidget {
  final Bus bus;

  const _BusMarker({
    required this.bus,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${bus.busId}\nRoute: ${bus.routeId}\nSpeed: ${bus.speedKmh.toStringAsFixed(1)} km/h',
      child: Container(
        decoration: BoxDecoration(
          color: bus.occupancy.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              spreadRadius: 1,
              color: Colors.black26,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_bus,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}

