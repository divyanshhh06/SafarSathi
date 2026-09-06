import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../modelss/bus.dart';
import '../modelss/bus_route.dart';

class BusInfoCard extends StatelessWidget {
  final Bus bus;
  final BusRoute? route;
  final VoidCallback? onClose;

  const BusInfoCard({
    super.key,
    required this.bus,
    this.route,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final speedKmh = bus.speedKmh;
    final occupancyColor = bus.occupancy.color;
    final occupancyLabel = bus.occupancy.label('en');

    final nextStopInfo = _estimateNextStop(route);
    final etaText = nextStopInfo != null
        ? '${nextStopInfo['etaMinutes']?.toStringAsFixed(1) ?? '--'} min to ${nextStopInfo['name']}'
        : 'ETA --';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: occupancyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: occupancyColor, width: 1.2),
                  ),
                  child: Text(
                    occupancyLabel,
                    style: TextStyle(
                      color: occupancyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Row(
              children: [
                Text(
                  bus.busId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1F57),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bus.isDwelling ? Colors.amber.shade100 : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bus.direction == 'returning' ? '↩️ Returning' : '➔ Forward',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: bus.isDwelling ? Colors.amber.shade900 : Colors.indigo.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bus.isDwelling)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Dwelling at station (Passenger Boarding - 30s)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                const Icon(Icons.speed_rounded, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  bus.isDwelling ? '0.0 km/h (Stopped)' : '${speedKmh.toStringAsFixed(1)} km/h',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bus.isDwelling ? Colors.orange.shade800 : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  etaText,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            if (route != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.route_rounded, color: Colors.deepOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route!.getLocalizedName('en'),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _estimateNextStop(BusRoute? route) {
    if (route == null || route.path.isEmpty) return null;

    final busPos = bus.position;
    double minDist = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < route.path.length; i++) {
      final d = Distance().as(LengthUnit.Kilometer, busPos, route.path[i]);
      if (d < minDist) {
        minDist = d;
        nearestIndex = i;
      }
    }

    final nextIndex = min(nearestIndex + 1, route.path.length - 1);
    final nextStop = route.stops.isNotEmpty
        ? route.stops[nextIndex.clamp(0, route.stops.length - 1)]
        : null;

    final distanceToNext = Distance().as(
      LengthUnit.Kilometer,
      busPos,
      route.path[nextIndex],
    );

    final speed = bus.speedKmh;
    final etaMinutes = speed > 0.5 ? (distanceToNext / speed) * 60 : null;

    return {
      'name': nextStop?.name ?? 'Next stop',
      'etaMinutes': etaMinutes,
    };
  }
}
