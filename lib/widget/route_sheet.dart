import 'package:flutter/material.dart';
import '../modelss/bus_route.dart';
import '../modelss/bus.dart';
import 'crowd_reporting_dialog.dart';

/// Bottom sheet overlay showing route details, stops, and crowd reporting.
class RouteSheet extends StatelessWidget {
  final BusRoute route;
  final List<Bus> liveBuses;
  final String currentLang;
  final ValueChanged<OccupancyLevel>? onOccupancyReported;

  const RouteSheet({
    super.key,
    required this.route,
    required this.liveBuses,
    this.currentLang = 'en',
    this.onOccupancyReported,
  });

  static void show(
    BuildContext context,
    BusRoute route,
    List<Bus> liveBuses, {
    String currentLang = 'en',
    ValueChanged<OccupancyLevel>? onOccupancyReported,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RouteSheet(
        route: route,
        liveBuses: liveBuses,
        currentLang: currentLang,
        onOccupancyReported: onOccupancyReported,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                route.getLocalizedName(currentLang),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                liveBuses.isEmpty
                    ? 'No buses currently active on this route'
                    : '${liveBuses.length} bus(es) active live now',
                style: TextStyle(
                  color: liveBuses.isEmpty ? Colors.grey : Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ...liveBuses.map(
                (bus) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bus.occupancy.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: bus.occupancy.color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.busId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bus.occupancy.color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      bus.occupancy.label(currentLang),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${bus.speedKmh.toStringAsFixed(0)} km/h',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 1-Tap Crowd Reporting Button ("Waze for Buses")
                        IconButton(
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            color: Colors.indigo,
                          ),
                          tooltip: 'Report Crowd Level',
                          onPressed: () {
                            CrowdReportingDialog.show(
                              context,
                              bus: bus,
                              currentLang: currentLang,
                              onReportSubmitted: (level) {
                                if (onOccupancyReported != null) {
                                  onOccupancyReported!(level);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Route Stops',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...route.stops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                final isLast = index == route.stops.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 38,
                            color: Colors.indigo.shade100,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.getLocalizedName(currentLang),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (stop.city.isNotEmpty)
                              Text(
                                '${stop.city}, ${stop.state}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
