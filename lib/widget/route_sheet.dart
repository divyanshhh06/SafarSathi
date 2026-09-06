import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../modelss/bus_route.dart';
import '../modelss/bus.dart';
import '../servicess/eta_service.dart';

/// Glassmorphic Live Stop ETAs & Crowdsourced Occupancy Sheet
/// Designed to match the SafarSathi Web Portal Live Stop ETA Matrix.
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
      backgroundColor: Colors.transparent,
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
    final activeBus = liveBuses.isNotEmpty ? liveBuses.first : null;
    final Distance distance = const Distance();

    // Identify nearest stop index for the active bus
    int nextStopIndex = 0;
    if (activeBus != null && route.stops.isNotEmpty) {
      double minDist = double.infinity;
      for (int i = 0; i < route.stops.length; i++) {
        final d = distance.as(
          LengthUnit.Kilometer,
          activeBus.position,
          route.stops[i].position,
        );
        if (d < minDist) {
          minDist = d;
          nextStopIndex = i;
        }
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A), // Dark Slate matching Web Portal
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView(
              controller: scrollController,
              children: [
                // Top Handle Bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded, color: Color(0xFF38BDF8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⏱️ Live Stop ETAs — ${route.getLocalizedName(currentLang)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeBus != null
                            ? '🟢 Live Bus Active (${activeBus.speedKmh.toStringAsFixed(0)} km/h)'
                            : '⚡ Scheduled Route (Continuous Stream)',
                        style: TextStyle(
                          color: activeBus != null ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Crowdsourced Occupancy Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '👥 Crowdsourced Occupancy',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'FE-1 X-Factor',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF166534),
                                foregroundColor: const Color(0xFF4ADE80),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                onOccupancyReported?.call(OccupancyLevel.seatsAvailable);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reported: Seats Free 🟢')),
                                );
                              },
                              child: const Text('🟢 Seats Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF854D0E),
                                foregroundColor: const Color(0xFFFACC15),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                onOccupancyReported?.call(OccupancyLevel.standingOnly);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reported: Standing 🟡')),
                                );
                              },
                              child: const Text('🟡 Standing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF991B1B),
                                foregroundColor: const Color(0xFFF87171),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                onOccupancyReported?.call(OccupancyLevel.packed);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reported: Packed 🔴')),
                                );
                              },
                              child: const Text('🔴 Packed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Stop ETAs List
                ...route.stops.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final stop = entry.value;

                  double distKm = 0.0;
                  int etaMins = 0;
                  bool isPassed = false;
                  bool isNext = false;

                  if (activeBus != null) {
                    if (idx < nextStopIndex) {
                      isPassed = true;
                    } else {
                      distKm = distance.as(
                        LengthUnit.Kilometer,
                        activeBus.position,
                        stop.position,
                      );
                      etaMins = EtaService.calculateEtaMinutes(
                        busPos: activeBus.position,
                        targetPos: stop.position,
                        speedKmh: activeBus.speedKmh,
                      );
                      if (idx == nextStopIndex) isNext = true;
                    }
                  } else {
                    etaMins = (idx + 1) * 4;
                    distKm = (idx + 1) * 1.5;
                    if (idx == 0) isNext = true;
                  }

                  final cardBorderColor = isNext
                      ? const Color(0xFF22C55E)
                      : (isPassed ? Colors.transparent : const Color(0xFF334155));

                  final cardBgColor = isNext
                      ? const Color(0xFF0C1F14)
                      : const Color(0xFF1E293B);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cardBorderColor,
                        width: isNext ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.getLocalizedName(currentLang),
                                style: TextStyle(
                                  color: isPassed ? const Color(0xFF64748B) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    isPassed
                                        ? '✓ Passed'
                                        : (isNext ? '🟡 Next stop' : 'Upcoming'),
                                    style: TextStyle(
                                      color: isPassed
                                          ? const Color(0xFF64748B)
                                          : (isNext ? const Color(0xFFFACC15) : const Color(0xFF94A3B8)),
                                      fontSize: 12,
                                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (!isPassed && distKm > 0) ...[
                                    Text(
                                      ' · ${distKm.toStringAsFixed(2)} km',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ETA Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPassed
                                ? const Color(0xFF334155)
                                : (isNext ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            isPassed
                                ? '✓ Passed'
                                : (etaMins <= 1 ? '🟢 Arriving' : '$etaMins min'),
                            style: TextStyle(
                              color: isPassed ? const Color(0xFF94A3B8) : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
