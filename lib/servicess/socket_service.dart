import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../modelss/bus.dart';
import 'eta_service.dart';

/// Single source of truth for live bus data and BE-1 Socket.IO backend communication.
class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// Toggle to switch between local laptop backend and live cloud backend
  static const bool useLocalBackend = false;

  static String get backendUrl {
    if (!useLocalBackend) return 'https://safarsathi-backend-eteo.onrender.com';
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Calculates dynamic traffic-adjusted ETA in minutes
  static int calculateEtaMinutes({
    required LatLng busPos,
    required LatLng targetPos,
    required double speedKmh,
    String? fromStopId,
    String? toStopId,
  }) {
    return EtaService.calculateEtaMinutes(
      busPos: busPos,
      targetPos: targetPos,
      speedKmh: speedKmh,
      fromStopId: fromStopId,
      toStopId: toStopId,
    );
  }

  io.Socket? _socket;
  final StreamController<List<Bus>> _controller =
      StreamController<List<Bus>>.broadcast();

  final Map<String, Bus> _busMap = {};


  Stream<List<Bus>> connect({String? routeId}) {
    if (_socket == null) {

      _socket = io.io(
        backendUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        // ignore: avoid_print
        print('⚡ Connected to SafarSathi BE-1 tracking server ($backendUrl)');
        if (routeId != null) {
          joinRoute(routeId);
        }
      });

      // Listen for compressed live position stream event 'u' from server
      // Payload format: [lat, lng, busId, speed, routeId]
      _socket!.on('u', (data) {
        try {
          if (data is List && data.length >= 5) {
            final lat = (data[0] as num).toDouble();
            final lng = (data[1] as num).toDouble();
            final busId = data[2].toString();
            final speed = (data[3] as num).toDouble();
            final rId = data[4].toString();

            final existing = _busMap[busId];
            final bus = Bus(
              busId: busId,
              routeId: rId,
              position: LatLng(lat, lng),
              speedKmh: speed,
              occupancy: existing?.occupancy ?? OccupancyLevel.seatsAvailable,
            );

            _busMap[busId] = bus;
            if (!_controller.isClosed) {
              _controller.add(_busMap.values.toList());
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('Failed to parse compressed update payload: $e');
        }
      });

      // Legacy/Fallback listener for uncompressed bus updates
      _socket!.on('bus:update', (data) {
        try {
          final list = (data as List)
              .map((e) => Bus.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          for (final b in list) {
            _busMap[b.busId] = b;
          }
          if (!_controller.isClosed) _controller.add(_busMap.values.toList());
        } catch (e) {
          // ignore: avoid_print
          print('Failed to parse bus:update payload: $e');
        }
      });

      _socket!.onDisconnect((_) {
        // ignore: avoid_print
        print('Disconnected from SafarSathi tracking server');
      });
    }

    if (routeId != null) {
      joinRoute(routeId);
    }

    return _controller.stream;
  }

  /// Commuter joins a specific route channel on BE-1
  void joinRoute(String routeId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_route', routeId);
    }
  }

  /// Fetch initial bus position from BE-1 Redis cache
  Future<Map<String, dynamic>?> getInitialPosition(String busId) async {
    if (_socket == null || _socket?.connected != true) return null;
    final completer = Completer<Map<String, dynamic>?>();
    try {
      _socket!.emitWithAck('get_initial_position', busId, ack: (data) {
        if (data != null && data is Map) {
          completer.complete(Map<String, dynamic>.from(data));
        } else {
          completer.complete(null);
        }
      });
      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sends crowdsourced occupancy report to BE-2 REST API & BE-1 WebSocket
  Future<void> reportOccupancy(String busId, OccupancyLevel occupancy) async {
    final payload = {
      'busId': busId,
      'occupancy': occupancy.name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await http.post(
        Uri.parse('$backendUrl/api/buses/$busId/occupancy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      _socket?.emit('bus:occupancy_report', payload);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send occupancy report to backend: $e');
    }
  }

  /// Sends a single GPS reading from the driver app to BE-1's compressed live feed ('d_up').
  /// Compressed Payload format expected by server.js: [lat, lng, busId, speed, routeId]
  Future<bool> reportDriverLocation(Map<String, dynamic> pingJson) async {
    if (_socket == null || _socket?.connected != true) {
      connect();
      return false;
    }

    try {
      final compressedPayload = [
        pingJson['lat'],
        pingJson['lng'],
        pingJson['busId'].toString(),
        pingJson['speed'],
        pingJson['routeId'].toString(),
      ];

      _socket!.emit('d_up', compressedPayload);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Failed to emit driver location ping: $e');
      return false;
    }
  }

  /// Sends a driver-reported issue to BE-1/BE-2.
  Future<void> reportDriverIssue({
    required String busId,
    required String routeId,
    required String issueType,
    String? note,
  }) async {
    final payload = {
      'busId': busId,
      'routeId': routeId,
      'issueType': issueType,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await http.post(
        Uri.parse('$backendUrl/api/buses/$busId/issues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      _socket?.emit('bus:issue_report', payload);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send issue report to backend: $e');
    }
  }

  void dispose() {
    _socket?.dispose();
    _controller.close();
  }
}

