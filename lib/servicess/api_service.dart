import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelss/bus.dart';
import '../modelss/bus_route.dart';
import '../modelss/stop.dart';

class ApiService {
  static const String baseUrl = 'https://safarsathi-1-63eu.onrender.com/api';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

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
  // ROUTES
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
  // STOPS
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

    final Map<String, dynamic> decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> stops = decoded['stops'] as List<dynamic>;

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
  // HELPERS
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
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
