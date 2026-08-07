import 'package:latlong2/latlong.dart';

class RouteStop {
  final String id;
  final String name;
  final String namePa; // Punjabi label
  final String nameHi; // Hindi label
  final String city;
  final String state;
  final LatLng position;
  final bool? shelter;

  const RouteStop({
    required this.id,
    required this.name,
    this.namePa = '',
    this.nameHi = '',
    this.city = '',
    this.state = '',
    required this.position,
    this.shelter,
  });

  String getLocalizedName(String langCode) {
    if (langCode == 'pa' && namePa.isNotEmpty) return namePa;
    if (langCode == 'hi' && nameHi.isNotEmpty) return nameHi;
    return name;
  }

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Bus Stop',
      namePa: json['namePa'] as String? ?? '',
      nameHi: json['nameHi'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      shelter: json['shelter'] as bool?,
    );
  }
}

class BusRoute {
  final String id;
  final String name;
  final String namePa;
  final String nameHi;
  final List<RouteStop> stops;

  const BusRoute({
    required this.id,
    required this.name,
    this.namePa = '',
    this.nameHi = '',
    required this.stops,
  });

  String getLocalizedName(String langCode) {
    if (langCode == 'pa' && namePa.isNotEmpty) return namePa;
    if (langCode == 'hi' && nameHi.isNotEmpty) return nameHi;
    return name;
  }

  /// Path used to animate buses along the route stops.
  List<LatLng> get path => stops.map((s) => s.position).toList();
}
