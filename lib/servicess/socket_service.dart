import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../modelss/bus.dart';
import 'mock_data_service.dart';

/// Single source of truth for live bus data and backend communication.
class SocketService {
  static const bool useMock = true;
  static const String backendUrl = 'https://YOUR-BACKEND-URL.example.com';

  io.Socket? _socket;
  final MockDataService _mock = MockDataService();
  final StreamController<List<Bus>> _controller =
      StreamController<List<Bus>>.broadcast();

  StreamSubscription<List<Bus>>? _mockSub;

  Stream<List<Bus>> connect() {
    if (useMock) {
      _mockSub = _mock.busUpdates.listen((buses) {
        if (!_controller.isClosed) _controller.add(buses);
      });
      return _controller.stream;
    }

    _socket = io.io(
      backendUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('Connected to live tracking server');
    });

    _socket!.on('bus:update', (data) {
      try {
        final list = (data as List)
            .map((e) => Bus.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (!_controller.isClosed) _controller.add(list);
      } catch (e) {
        // ignore: avoid_print
        print('Failed to parse bus:update payload: $e');
      }
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('Disconnected from tracking server');
    });

    return _controller.stream;
  }

  /// Sends crowdsourced occupancy report to BE-2 REST API & BE-1 WebSocket
  Future<void> reportOccupancy(String busId, OccupancyLevel occupancy) async {
    final payload = {
      'busId': busId,
      'occupancy': occupancy.name, // 'seatsAvailable', 'standingOnly', 'packed'
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (useMock) {
      // ignore: avoid_print
      print('[MOCK] Sent occupancy report payload to BE-2: $payload');
      return;
    }

    try {
      // 1. Send HTTP POST to BE-2 REST API
      await http.post(
        Uri.parse('$backendUrl/api/buses/$busId/occupancy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // 2. Emit WebSocket event to BE-1 real-time engine
      _socket?.emit('bus:occupancy_report', payload);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send occupancy report to backend: $e');
    }
  }

  void dispose() {
    _mockSub?.cancel();
    _mock.dispose();
    _socket?.dispose();
    _controller.close();
  }
}
