import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../modelss/bus.dart';

/// Custom Tween that linearly interpolates between two LatLng points.
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final b = begin ?? end ?? const LatLng(0, 0);
    final e = end ?? begin ?? const LatLng(0, 0);
    return LatLng(
      b.latitude + (e.latitude - b.latitude) * t,
      b.longitude + (e.longitude - b.longitude) * t,
    );
  }
}

/// Smoothly animates bus marker position and displays speed & crowdsourced occupancy.
class AnimatedBusMarker extends StatefulWidget {
  final LatLng target;
  final double bearing;
  final double speedKmh;
  final OccupancyLevel occupancy;
  final Duration duration;
  final void Function(LatLng animatedPosition)? onPositionUpdate;

  const AnimatedBusMarker({
    super.key,
    required this.target,
    required this.bearing,
    required this.speedKmh,
    this.occupancy = OccupancyLevel.seatsAvailable,
    this.onPositionUpdate,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<AnimatedBusMarker> createState() => _AnimatedBusMarkerState();
}

class _AnimatedBusMarkerState extends State<AnimatedBusMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late LatLngTween _tween;
  late LatLng _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.target;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _tween = LatLngTween(begin: widget.target, end: widget.target);
  }

  @override
  void didUpdateWidget(covariant AnimatedBusMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _tween = LatLngTween(begin: _currentPosition, end: widget.target);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.occupancy == OccupancyLevel.seatsAvailable
        ? const Color(0xFF00E676) // Vivid Green
        : (widget.occupancy == OccupancyLevel.standingOnly
            ? const Color(0xFFFF9100) // Vivid Amber
            : const Color(0xFFFF1744)); // Vivid Red

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _currentPosition = _tween.evaluate(_controller);
        return SizedBox(
          width: 90,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed Badge (High Contrast Dark Indigo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F57),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.amberAccent, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 10, color: Colors.amberAccent),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.speedKmh.toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Glowing Bus Icon Pin with Radar Ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E1F57), width: 2.5),
                  ),
                  child: Transform.rotate(
                    angle: widget.bearing * 3.1415926535 / 180,
                    child: const Icon(
                      Icons.directions_bus_filled_rounded,
                      color: Color(0xFF1E1F57),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
