import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Fetches real road polyline geometry using OpenStreetMap's OSRM routing service.
class RoadRoutingService {
  /// Returns a detailed list of LatLng coordinates following actual roads
  /// between the provided waypoints.
  static Future<List<LatLng>> getRoadPath(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final coordinatesString = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinatesString?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          return coordinates.map<LatLng>((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      }
    } catch (_) {
      // Fallback to straight lines if offline or request fails
    }

    return waypoints;
  }
}
