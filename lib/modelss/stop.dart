import 'package:latlong2/latlong.dart';

class BusStop {
  final String id;
  final String name;
  final LatLng position;
  final String? address;
  final bool active;

  const BusStop({
    required this.id,
    required this.name,
    required this.position,
    this.address,
    this.active = true,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: LatLng(
        (json['lat'] as num?)?.toDouble() ?? 0.0,
        (json['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      address: json['address']?.toString(),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': position.latitude,
      'lng': position.longitude,
      'address': address,
      'active': active,
    };
  }

  BusStop copyWith({
    String? id,
    String? name,
    LatLng? position,
    String? address,
    bool? active,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      address: address ?? this.address,
      active: active ?? this.active,
    );
  }
}
