import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../modelss/bus.dart';
import '../modelss/route_model.dart';
import '../modelss/stop.dart';

class ApiService {
  static const String _localBaseUrl = 'http://localhost:3000/api';
  static const String _renderBaseUrl = 'https://safarsathi-1e51.onrender.com/api';

  static String get baseUrl => kReleaseMode ? _renderBaseUrl : _localBaseUrl;

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
