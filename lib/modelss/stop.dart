import 'package:latlong2/latlong.dart';

class District {
  final String slug;
  final String name;
  final int stopCount;

  const District({
    required this.slug,
    required this.name,
    required this.stopCount,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      stopCount: json['stopCount'] is int ? json['stopCount'] as int : int.tryParse(json['stopCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class BusStop {
  final String id;
  final String name;
  final String city;
  final String state;
  final String country;
  final LatLng position;
  final String? type;
  final bool? publicTransport;
  final bool? shelter;

  const BusStop({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    this.country = 'India',
    required this.position,
    this.type,
    this.publicTransport,
    this.shelter,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'] ?? json['lat'];
    final lng = json['longitude'] ?? json['lng'];
    return BusStop(
      id: json['id']?.toString() ?? json['stop_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['stop_name']?.toString() ?? 'Bus Stop',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      position: LatLng(
        (lat as num?)?.toDouble() ?? 0.0,
        (lng as num?)?.toDouble() ?? 0.0,
      ),
      type: json['type']?.toString(),
      publicTransport: json['publicTransport'] as bool?,
      shelter: json['shelter'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type,
      'publicTransport': publicTransport,
      'shelter': shelter,
    };
  }

  BusStop copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    String? country,
    LatLng? position,
    String? type,
    bool? publicTransport,
    bool? shelter,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      position: position ?? this.position,
      type: type ?? this.type,
      publicTransport: publicTransport ?? this.publicTransport,
      shelter: shelter ?? this.shelter,
    );
  }
}
