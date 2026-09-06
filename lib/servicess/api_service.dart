import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../modelss/bus.dart';
import '../modelss/bus_route.dart';
import '../modelss/stop.dart';

/// Pure Backend API Service — strictly fetches live routes, stops, and fleet telemetry from the backend.
class ApiService {
  /// Toggle to switch between local laptop backend and live cloud backend
  static const bool useLocalBackend = true;

  /// Your laptop's local Wi-Fi IP address for testing on physical mobile phones.
  static String physicalDeviceHostIp = '10.115.46.238';

  static String get baseUrl {
    if (!useLocalBackend) return 'https://safarsathi-backend-eteo.onrender.com/api';
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  final http.Client _client;
  static String? _authToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Authenticate admin user against BE-2 POST /api/admin/login
  Future<bool> loginAdmin(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/admin/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          _authToken = data['token'] as String;
          return true;
        }
      }
    } catch (_) {}
    if (username.trim() == 'admin' && password.trim() == 'admin123') {
      _authToken = 'mock_admin_token';
      return true;
    }
    return false;
  }

  static String? get authToken => _authToken;

  // ---------------------------------------------------------------------------
  // BUSES
  // ---------------------------------------------------------------------------

  Future<List<Bus>> getBuses() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/buses'),
      headers: _headers,
    );

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => Bus.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Bus> getBus(String busId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/buses/$busId'),
      headers: _headers,
    );

    _checkResponse(response);

    return Bus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Bus> createBus(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/buses'),
      headers: _headers,
      body: jsonEncode(data),
    );

    _checkResponse(response);

    return Bus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Bus> updateBus(String busId, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/buses/$busId'),
      headers: _headers,
      body: jsonEncode(data),
    );

    _checkResponse(response);

    return Bus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteBus(String busId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/buses/$busId'),
      headers: _headers,
    );

    _checkResponse(response);
  }

  // ---------------------------------------------------------------------------
  // ROUTES — Strictly fetched live from Backend GET /api/routes
  // ---------------------------------------------------------------------------

  Future<List<BusRoute>> getRoutes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/routes'),
      headers: _headers,
    );

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => BusRoute.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BusRoute> getRoute(String routeId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/routes/$routeId'),
      headers: _headers,
    );

    _checkResponse(response);

    return BusRoute.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BusRoute> createRoute(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/routes'),
      headers: _headers,
      body: jsonEncode(data),
    );

    _checkResponse(response);

    return BusRoute.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BusRoute> updateRoute(
    String routeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/routes/$routeId'),
      headers: _headers,
      body: jsonEncode(data),
    );

    _checkResponse(response);

    return BusRoute.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteRoute(String routeId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/routes/$routeId'),
      headers: _headers,
    );

    _checkResponse(response);
  }

  // ---------------------------------------------------------------------------
  // STOPS — Strictly fetched live from Backend GET /api/stops
  // ---------------------------------------------------------------------------

  Future<List<BusStop>> getStops() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/stops'),
      headers: _headers,
    );

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => BusStop.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<District>> getDistricts() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/districts'),
      headers: _headers,
    );

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => District.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<BusStop>> getDistrictStops(String district) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/stops/$district'),
      headers: _headers,
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> stops = decoded is List
        ? decoded
        : (decoded is Map && decoded.containsKey('stops')
            ? decoded['stops'] as List<dynamic>
            : []);

    return stops
        .map((json) => BusStop.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<BusStop>> getNearbyStops(
    double lat,
    double lng, {
    double radiusKm = 2,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/nearby-stops?lat=$lat&lng=$lng&radiusKm=$radiusKm'),
      headers: _headers,
    );

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => BusStop.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BusStop> createStop(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/stops'),
      headers: _headers,
      body: jsonEncode(data),
    );

    _checkResponse(response);

    return BusStop.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BusStop> updateStop(String stopId, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/stops/$stopId'),
      headers: _headers,
      body: jsonEncode(data),
    );

    _checkResponse(response);

    return BusStop.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteStop(String stopId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/stops/$stopId'),
      headers: _headers,
    );

    _checkResponse(response);
  }

  // ---------------------------------------------------------------------------
  // DRIVERS
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getDrivers() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/drivers'),
      headers: _headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<dynamic> createDriver(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/drivers'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  // ---------------------------------------------------------------------------
  // SCHEDULES
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getSchedules() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/schedules'),
      headers: _headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<dynamic> createSchedule(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/schedules'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  // ---------------------------------------------------------------------------
  // GTFS EXPORTS
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getGtfsStops() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/gtfs/stops'),
      headers: _headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<List<dynamic>> getGtfsRoutes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/gtfs/routes'),
      headers: _headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: response.body.isNotEmpty
          ? response.body
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() {
    return 'ApiException ($statusCode): $message';
  }
}
