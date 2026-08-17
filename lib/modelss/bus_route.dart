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
  final List<LatLng> path;
  final String? color;

  const BusRoute({
    required this.id,
    required this.name,
    this.namePa = '',
    this.nameHi = '',
    required this.stops,
    required this.path,
    this.color,
  });

  String getLocalizedName(String langCode) {
    if (langCode == 'pa' && namePa.isNotEmpty) return namePa;
    if (langCode == 'hi' && nameHi.isNotEmpty) return nameHi;
    return name;
  }

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List<dynamic>? ?? [];
    final pathJson = json['path'] as List<dynamic>? ?? [];
    return BusRoute(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Bus Route',
      namePa: json['namePa'] as String? ?? '',
      nameHi: json['nameHi'] as String? ?? '',
      stops: stopsJson
          .map((s) => RouteStop.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      path: pathJson.map((p) {
        final coords = p as List<dynamic>;
        return LatLng(
          (coords[0] as num).toDouble(),
          (coords[1] as num).toDouble(),
        );
      }).toList(),
      color: json['color'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusRoute &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'namePa': namePa,
      'nameHi': nameHi,
      'stops': stops.map((s) {
        return {
          'id': s.id,
          'name': s.name,
          'namePa': s.namePa,
          'nameHi': s.nameHi,
          'city': s.city,
          'state': s.state,
          'latitude': s.position.latitude,
          'longitude': s.position.longitude,
          'shelter': s.shelter,
        };
      }).toList(),
      'path': path.map((p) => [p.latitude, p.longitude]).toList(),
      'color': color,
    };
  }

  BusRoute copyWith({
    String? id,
    String? name,
    String? namePa,
    String? nameHi,
    List<RouteStop>? stops,
    List<LatLng>? path,
    String? color,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      namePa: namePa ?? this.namePa,
      nameHi: nameHi ?? this.nameHi,
      stops: stops ?? this.stops,
      path: path ?? this.path,
      color: color ?? this.color,
    );
  }
}