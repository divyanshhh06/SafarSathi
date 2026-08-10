import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../modelss/bus_route.dart';
import '../servicess/location_service.dart';
import '../servicess/mock_data_service.dart';
import '../servicess/socket_service.dart';

/// FE-3: Driver Module home screen.
///
/// Big-touch-target UI for a driver to start/end a trip and report issues.
/// GPS streams every ~7s via [LocationService], queued locally in Hive and
/// flushed to BE-1/BE-2 whenever the network is available -- so a dropped
/// signal on the road never loses a ping.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const _tripStateBox = 'trip_state';

  final SocketService _socketService = SocketService();
  late final LocationService _locationService = LocationService(
    socketService: _socketService,
  );

  bool _isTripActive = false;
  String? _busId;
  BusRoute? _selectedRoute;
  int _pendingPings = 0;

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  void _restoreState() {
    final box = Hive.box(_tripStateBox);
    final savedBusId = box.get('busId') as String?;
    final savedRouteId = box.get('routeId') as String?;

    if (savedBusId != null && savedRouteId != null) {
      final route = MockDataService.routes.firstWhere(
            (r) => r.id == savedRouteId,
        orElse: () => MockDataService.routes.first,
      );
      setState(() {
        _isTripActive = true;
        _busId = savedBusId;
        _selectedRoute = route;
      });
      _locationService.startTracking(busId: savedBusId, routeId: route.id);
    }
  }

  Future<void> _startTrip() async {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a route before starting the trip')),
      );
      return;
    }

    final busId = 'driver-${const Uuid().v4().substring(0, 8)}';
    final box = Hive.box(_tripStateBox);

    try {
      await _locationService.startTracking(
        busId: busId,
        routeId: _selectedRoute!.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start GPS tracking: $e')),
      );
      return;
    }

    await box.put('busId', busId);
    await box.put('routeId', _selectedRoute!.id);

    setState(() {
      _isTripActive = true;
      _busId = busId;
    });
  }

  Future<void> _endTrip() async {
    await _locationService.stopTracking();
    final box = Hive.box(_tripStateBox);
    await box.delete('busId');
    await box.delete('routeId');

    setState(() {
      _isTripActive = false;
      _busId = null;
    });
  }

  void _reportIssue() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _IssueSheet(
        onSubmit: (issueType, note) async {
          if (_busId == null || _selectedRoute == null) return;
          await _socketService.reportDriverIssue(
            busId: _busId!,
            routeId: _selectedRoute!.id,
            issueType: issueType,
            note: note,
          );
          if (sheetContext.mounted) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(content: Text('Issue reported')),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // Intentionally NOT calling stopTracking() here -- if the widget is
    // disposed because the app is backgrounded mid-trip, tracking should
    // keep running. Only the explicit "End Trip" button should stop it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Poll the pending-sync count for the small status readout.
    if (_isTripActive) {
      _pendingPings = _locationService.pendingCount;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!_isTripActive) _RoutePicker(
                selected: _selectedRoute,
                onChanged: (route) => setState(() => _selectedRoute = route),
              ),
              if (_isTripActive)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${_selectedRoute?.name ?? ''}'
                        '${_pendingPings > 0 ? '  •  $_pendingPings ping(s) queued offline' : '  •  synced'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _BigButton(
                  label: _isTripActive ? 'END TRIP' : 'START TRIP',
                  color: _isTripActive ? Colors.red : Colors.green,
                  onTap: _isTripActive ? _endTrip : _startTrip,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: _BigButton(
                  label: 'REPORT ISSUE',
                  color: Colors.orange,
                  onTap: _isTripActive ? _reportIssue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePicker extends StatelessWidget {
  final BusRoute? selected;
  final ValueChanged<BusRoute?> onChanged;

  const _RoutePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BusRoute>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Route',
        border: OutlineInputBorder(),
      ),
      items: MockDataService.routes
          .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _BigButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? color.withValues(alpha: 0.4) : color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _IssueSheet extends StatefulWidget {
  final Future<void> Function(String issueType, String? note) onSubmit;

  const _IssueSheet({required this.onSubmit});

  @override
  State<_IssueSheet> createState() => _IssueSheetState();
}

class _IssueSheetState extends State<_IssueSheet> {
  String _issueType = 'breakdown';
  final _noteController = TextEditingController();

  static const _issueTypes = {
    'breakdown': 'Vehicle Breakdown',
    'traffic': 'Heavy Traffic Delay',
    'accident': 'Accident / Incident',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Report an Issue', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._issueTypes.entries.map(
            // ignore: deprecated_member_use
            (entry) => RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              // ignore: deprecated_member_use
              groupValue: _issueType,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _issueType = v!),
            ),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await widget.onSubmit(_issueType, _noteController.text.trim());
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}