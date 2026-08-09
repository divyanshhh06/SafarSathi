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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _currentPosition = _tween.evaluate(_controller);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${widget.speedKmh.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.occupancy.color.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: widget.occupancy.color, width: 2),
              ),
              child: Transform.rotate(
                angle: widget.bearing * 3.1415926535 / 180,
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: widget.occupancy.color,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
