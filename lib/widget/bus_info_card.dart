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
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.speed_rounded, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${speedKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
